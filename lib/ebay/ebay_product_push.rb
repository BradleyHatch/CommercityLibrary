# frozen_string_literal: true

# Here are all of the methods that push data to eBay with a single product
# listing
#
# Most of them just set up the call and then passes off the xml set up
# to the #product method

module EbayProductPush
  extend ActiveSupport::Concern

  def verify_product(val)
    variant = val.flatten[1].main_variant
    product('VerifyAddFixedPriceItem', variant) unless variant.item_id
  end

  def add_product(val)
    val = val.flatten[1]
    val.variants.each do |variant|
      product('AddFixedPriceItem', variant) unless variant.item_id
    end
  end

  def revise_product(val)
    val = val.flatten[1]
    val.variants.each do |variant|
      product('ReviseFixedPriceItem', variant) if variant.item_id
    end
  end

  def add_or_revise_variants(val)
    val = val.flatten[1]
    val.variants.each do |variant|
      next unless variant.active? && variant.published_ebay
      variant.update(ebay_last_push_success: nil)
      call = variant.item_id? ? 'ReviseFixedPriceItem' : 'AddFixedPriceItem'
      product(call, variant)
    end
  end

  def end_listing(val)
    request = EbayTrader::Request.new('EndFixedPriceItem') do
      WarningLevel 'High'
      EndingReason 'NotAvailable'
      ItemID val
    end
    request.response_hash
  end

  def relist_product(val)
     request = EbayTrader::Request.new('RelistFixedPriceItem') do
       Item do
         ItemID val.main_variant.item_id
       end
     end
     val.ebay_channel.update(ended: false)
     val.main_variant.update(item_id: request.response_hash[:item_id])
     request.response_hash
   end


  def product(call, val)
    val.update(published_ebay: true) unless call == 'VerifyAddFixedPriceItem'
    ebay_body = val.ebay_channel.subbed_shop_wrap(val.channel_description_fallback('ebay'), val.price(channel: :ebay, fallback: :web))
    ebay_title = val.ebay_title_fallback
    request = EbayTrader::Request.new(call) do
      ErrorLanguage 'en_GB'
      WarningLevel 'High'
      DetailLevel 'ReturnAll'

      Item do
        SKU val.ebay_sku
        ItemID val.item_id if call == 'ReviseFixedPriceItem'
        Title "<![CDATA[#{ebay_title}]]>"
        SubTitle val.ebay_channel.sub_title
        Description "<![CDATA[#{ebay_body}]]>"

        ProductListingDetails do
          IncludeeBayProductDetails !!val&.ebay_channel&.uses_ebay_catalogue

          if val.brand.present? && val.mpn.present?
            BrandMPN do
              Brand val.brand.name if val.brand
              MPN val.mpn if val.mpn
            end
          end

          if val.no_barcodes
            EAN val.barcode_does_not_apply_text
          else
            val.barcodes.each do |barcode|
              case barcode.symbology
              when 'UPC'
                UPC barcode.value
              when 'EAN'
                EAN barcode.value
              when 'GTIN'
                GTIN barcode.value
              when 'ISBN'
                ISBN barcode.value
              else
                Logger.info 'No Barcode'
              end
            end
          end
        end

        if (val.brand.present? && val.mpn.present?) || val.property_values.any?
          ItemSpecifics do
            if val.property_values.any?
              val.property_values.each do |property|
                NameValueList do
                  Name property.key
                  Value property.value
                end
              end
            end
            if val.brand.present? && val.mpn.present?
              NameValueList do
                Name 'Manufacturer Part Number'
                Value val.mpn
              end
              NameValueList do
                Name 'Brand'
                Value val.brand.name
              end
            end
          end
        end

        PrimaryCategory do
          CategoryID val.ebay_channel.category_fallback
        end

        StartPrice val.price(channel: :ebay, fallback: :web).to_s
        CategoryMappingAllowed true
        ConditionID val.ebay_channel.condition
        ConditionDescription val.ebay_channel.condition_description
        Country val.ebay_channel.country
        Currency val.price(channel: :ebay, fallback: :web).currency.id.to_s.upcase
        ListingDuration val.ebay_channel.duration
        ListingType 'FixedPriceItem' if call == 'AddFixedPriceItem'
        PaymentMethods 'PayPal' if val.ebay_channel.payment_method_paypal
        PaymentMethods 'Escrow' if val.ebay_channel.payment_method_escrow
        PaymentMethods 'PersonalCheck' if val.ebay_channel.payment_method_cheque
        PaymentMethods 'PostalTransfer' if val.ebay_channel.payment_method_postal
        PaymentMethods 'CCAccepted' if val.ebay_channel.payment_method_cc
        PaymentMethods 'MOCC' if val.ebay_channel.payment_method_money_order
        PaymentMethods 'Other' if val.ebay_channel.payment_method_other
        PaymentMethods 'CashOnPickup' if val.ebay_channel.pickup_in_store
        PayPalEmailAddress C.ebay_paypal

        PickupInStoreDetails do
          EligibleForPickupInStore val.ebay_channel.pickup_in_store?
          EligibleForPickupDropOff val.ebay_channel.click_collect_collection_available?
        end

        if val.images.empty?
          images = { channel: true, collection: val.ebay_channel.channel_images }
          if images[:collection].empty?
            images = { channel: true, collection: val.web_channel.channel_images }
            if images[:collection].empty?
              images = { channel: false, collection: val.master.images }
            end
          end
        else
          images = { channel: false, collection: val.images }
        end

        PictureDetails do
          images[:collection].ordered.each do |image|
            if images[:channel]
              PictureURL image.image.image.ebay_image.url
            else
              PictureURL image.image.ebay_image.url
            end
          end
        end

        PostalCode val.ebay_channel.postcode
        Quantity val.quantity_check

        # dont both trying to push shipping stuff when no shipping services have
        # been set. should default to collection on ebay

        DispatchTimeMax val.ebay_channel.dispatch_time || 0

        if val.ebay_channel.no_shipping_options

          ShippingDetails do
            ShippingServiceOptions do
              ShippingService 'UK_CollectInPerson'
              ShippingServiceCost 0
              ShippingServiceAdditionalCost 0
              ShippingServicePriority 1
            end
          end

        else

          ShippingDetails do
            ShippingType val.ebay_channel.domestic_shipping_type
            GlobalShipping val.ebay_channel.global_shipping

            # Domestic shipping
            if val.ebay_channel.domestic_services.count > 0
              val.ebay_channel.domestic_services.each do |service|
                next if service.delivery_service.ebay_alias.blank?
                ShippingServiceOptions do
                  ShippingServicePriority 1
                  ShippingService service.delivery_service.ebay_alias
                  ShippingServiceCost service.default_cost
                  ShippingServiceAdditionalCost service.default_additional_cost
                end
              end
            end

            # International Shipping
            if val.ebay_channel.international_services.count > 0
              val.ebay_channel.international_services.each do |service|
                # Skipping InternationalPriorityShippingUK as its a global shipping
                # service you can't supply reguarly but is synced as an eBay shipping service
                next if service.delivery_service.ebay_alias.blank? || service.delivery_service.ebay_alias == 'InternationalPriorityShippingUK'
                InternationalShippingServiceOption do
                  ShippingServicePriority 1
                  ShippingService service.delivery_service.ebay_alias
                  ShippingServiceCost service.cost
                  ShippingServiceAdditionalCost service.additional_cost

                  val.ebay_channel.ship_to_locations.each do |ship_to|
                    ShipToLocation ship_to.code
                  end
                end
              end
            end
          end

        end

        ShippingPackageDetails do
          MeasurementUnit 'Metric'
          ShippingPackage val.master.ebay_channel.package_type if val.master.ebay_channel.package_type
          WeightMajor val.master.main_variant.weight if val.master.main_variant.weight.present? && C.ebay_package_details.include?("weight")
          PackageDepth val.master.main_variant.z_dimension if val.master.main_variant.z_dimension.present? && C.ebay_package_details.include?("depth")
          PackageLength val.master.main_variant.y_dimension if val.master.main_variant.y_dimension.present? && C.ebay_package_details.include?("height")
          PackageWidth val.master.main_variant.x_dimension if val.master.main_variant.x_dimension.present? && C.ebay_package_details.include?("width")
        end

        ReturnPolicy do
          ReturnsAcceptedOption val.ebay_channel.returns_accepted ? 'ReturnsAccepted' : 'ReturnsNotAccepted'
          RestockingFeeValueOption val.ebay_channel.restocking_fee_value_option
          Description "<![CDATA[#{val.ebay_channel.returns_description}]]>"
          RefundOption val.ebay_channel.refund_option
          ReturnsWithinOption val.ebay_channel.returns_within
          ShippingCostPaidByOption val.ebay_channel.returns_cost_paid_by

          WarrantyDurationOption val.ebay_channel.warranty_duration
          WarrantyOfferedOption true if val.ebay_channel.warranty_offered
          WarrantyTypeOption val.ebay_channel.warranty_type
        end
      end
    end

    val.update_push_status(request.response_hash) unless call == 'VerifyAddFixedPriceItem'
    val.update_push_body(request.response_hash) unless call == 'VerifyAddFixedPriceItem'

    val.update(item_id: request.response_hash[:item_id]) if call == 'AddFixedPriceItem'
    val.update(has_been_pushed_to_ebay: true) if val.item_id

    request.response_hash
  end
end
