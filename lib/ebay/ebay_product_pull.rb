# frozen_string_literal: true

# This is all of calls to ebay that grab listing data and then processes it in
# some form such as getting a listing, creating a local record of that listing,
# syncing details to already stored listings etc etc.

# PROTIP: most of these methods require the lib/ebay/classes/listing file but
# it is handily required in the EbayJob.rb

module EbayProductPull
  extend ActiveSupport::Concern

  def get_item(val)
    request = EbayTrader::Request.new('GetItem') do
      WarningLevel 'High'
      ItemID val.flatten[1]
      IncludeItemSpecifics true
      DetailLevel 'ReturnAll'
    end
    request.response_hash[:item]
  end

  def create_single_local_item(item_id)
    if (local_listing = C::Product::Variant.find_by(item_id: item_id[:obj]))
      local_listing
    else
      listing = get_item(obj: item_id[:obj])
      if listing
        begin
          build_local_ebay(listing)
          C::Product::Variant.find_by(item_id: item_id[:obj])
        rescue Exception => e
          logger.info e.message
          e.message
        end
      else
        'Invalid ItemID'
      end
    end
  end

  def build_local_ebay(listing, set_sku_as_item_id=false)
    master = C::Product::Master.new
    listing_obj = Ebay::Listing.new(listing)

    if set_sku_as_item_id
      sku = listing_obj.item_id
    else
      sku = listing_obj.sku || listing_obj.mpn || listing_obj.product_details[:ean]
    end

    master.build_main_variant(
      sku: sku, name: listing_obj.title,
      status: :active, published_amazon: false,
      published_ebay: true, published_web: false,
      item_id: listing_obj.item_id
    )

    master.build_ebay_channel
    master.main_variant.build_ebay_price
    master.save!

    build_local_images(listing_obj, master)

    update_local_ebay_channel(master, master.main_variant, listing_obj)
  end

  def build_local_images(listing_obj, master)
    # this errors in sandbox because it destroys product from s3 and ebay returns our s3 links
    if listing_obj.picture_urls
      remote_image_array = to_array(listing_obj.picture_urls)
      remote_image_array.each_with_index do |picture, i|
        # Begin rescue to block to prevent errors when 403 for unavailable asset
        begin
          new_image = master.images.create!(remote_image_url: picture.gsub('$_1', '$_57'))
          img = master.ebay_channel.channel_images.create!(image: new_image)
          weight = img._weight
          weight.update(value: i)

          weight = new_image._weight
          weight.update(value: i)
        rescue ActiveRecord::RecordInvalid
          logger.info 'Invalid Image'
        end
      end
    end
  end

  def sync_product(val)
    master = val[:obj]
    variants = master.variants.where.not(item_id: nil)

    variants.each do |variant|
      listing_obj = Ebay::Listing.new(get_item(obj: variant.item_id))

      next unless listing_obj.item_id
      variant.update(status: :active, published_ebay: true)

      listing_response = update_local_ebay_channel(variant.master, variant, listing_obj)

      # only changing the published_web value from ebay sync if the c variable has been set
      variant.update(published_web: true) if C.default_published_web

      # Update eBay channel last sync time if Active status has been returned
      # because this assumes successful GetItem request for this item_id
      # Also setting sku equal to mpn if it was previously imported and set to
      # the eBay item id
      status = listing_response[:selling_status][:listing_status]
      variant.ebay_channel.update(last_sync_time: Time.now) if status == 'Active' || status == 'Ended' || status == 'Completed'
      variant.ebay_channel.update(ended: true) if status == 'Ended' || status == 'Completed'
      variant.update(sku: variant.mpn) if variant.sku == variant.item_id && variant.mpn && variant.ebay_channel.last_sync_time
    end
  end

  def update_local_ebay_channel(master, variant, listing_obj)
    channel = master.ebay_channel

    variant.update(current_stock: listing_obj.computed_stock, item_id: listing_obj.item_id)

    desc, text1, text2 = channel.subbed_text(listing_obj.body)

    channel.update({ name: listing_obj.title,
                     sub_title: listing_obj.sub_title,
                     condition: listing_obj.condition_id,
                     description: desc,
                     wrap_text_1: text1,
                     wrap_text_2: text2,
                     postcode: listing_obj.postcode,
                     duration: listing_obj.duration,
                     country: listing_obj.country,
                     dispatch_time: listing_obj.dispatch_time,
                     returns_accepted: listing_obj.returns_accepted,
                     condition_description: listing_obj.condition_description }.reject { |_k, v| v.blank? })

    sync_item_specifics(listing_obj, variant)
    sync_barcode(listing_obj, variant)
    sync_category(listing_obj, channel)
    sync_shipping_information(listing_obj, channel)
    sync_shipping_options(listing_obj, channel, 'domestic')
    sync_shipping_options(listing_obj, channel, 'international')
    sync_manufacturer_info(listing_obj, variant, master)
    sync_pickup_in_store(listing_obj, channel)
    sync_price(listing_obj, variant)
    sync_returns_policy(listing_obj, channel)
    sync_ship_to_locations(listing_obj, channel)
    sync_warranty(listing_obj, channel)
    sync_weight(listing_obj, channel)
    sync_ebay_sku(listing_obj, variant)
    sync_store_categories(listing_obj, master)
    sync_status(variant)

    to_array(listing_obj.payment_methods).map { |method| channel.update(channel.payment_method_evaluate(method)) }

    listing_obj.listing
  end

  # Grabbing MPN that may not be set in MPN container, but rather as NameValue pair
  def sync_item_specifics(listing_obj, variant)
    if listing_obj.name_value_list
      to_array(listing_obj.name_value_list).each do |name_value|
        next unless name_value[:name] && name_value[:value]
        if name_value[:name] == 'Manufacturer Part Number' || name_value[:name] == 'Part Manufacturer Number'
          variant.update(mpn: name_value[:value])
        else
          key = C::Product::PropertyKey.find_or_create_by(key: name_value[:name].strip)
          val = variant.property_values.find_or_create_by(property_key_id: key.id, value: name_value[:value].to_s.strip)
        end
      end
    end
  end

  def sync_barcode(listing_obj, variant)
    if listing_obj.product_details && listing_obj.product_details[:ean]
      if listing_obj.product_details[:ean] == variant.barcode_does_not_apply_text
        variant.update(no_barcodes: true)
        return
      else
        variant.update(no_barcodes: false)
      end
      variant.barcodes.find_or_create_by(symbology: :EAN).tap do |barcode|
        barcode.value = listing_obj.product_details[:ean]
        barcode.save
      end
    end
  end

  def sync_category(listing_obj, channel)
    if (category = C::EbayCategory.find_by(category_id: listing_obj.primary_category_id))
      channel.update(ebay_category: category)
    end
  end

  def sync_shipping_information(listing_obj, channel)
    channel.update(no_shipping_options: listing_obj.no_shipping_options?)
    return if channel.no_shipping_options?

    if listing_obj.domestic_options && (ebay_shipping = to_array(listing_obj.domestic_options).first)
      channel.update({
        domestic_shipping_type: listing_obj.shipping_details[:shipping_type],
        global_shipping: listing_obj.shipping_details[:global_shipping]
      }.reject { |_k, v| v.blank? })
    end
  end

  def sync_shipping_options(listing_obj, channel, type='domestic')
    return if channel.no_shipping_options?

    if (shipping_options = to_array(listing_obj.send("#{type}_options")))
      shipping_options.each do |shipping_option|
        delivery_service = delivery_service_create({ebay_alias: shipping_option[:shipping_service]}, shipping_option[:shipping_service_cost], channel.id)
        local_shipping = channel.shipping_services.find_or_create_by(delivery_service: delivery_service)
        local_shipping.update(cost: shipping_option[:shipping_service_cost],
                              additional_cost: shipping_option[:shipping_service_additional_cost],
                              international: (type == 'international'),
                              ship_time_min: shipping_option[:shipping_time_min],
                              ship_time_max: shipping_option[:shipping_time_max],
                              expedited: shipping_option[:expedited]
                              )
      end
    end
  end

  def sync_manufacturer_info(listing_obj, variant, master)
    if listing_obj.product_details && listing_obj.product_details[:brand_mpn]
      mpn = listing_obj.product_details[:brand_mpn][:mpn].blank? ? listing_obj.sku : listing_obj.product_details[:brand_mpn][:mpn]
      brand = C::Brand.find_or_create_by(name: listing_obj.product_details[:brand_mpn][:brand])
      variant.update(mpn: mpn)
      master.update(brand_id: brand.id, manufacturer_id: brand.id)
    end
  end

  def sync_pickup_in_store(listing_obj, channel)
    if listing_obj.pickup_in_store_details.present?
      channel.update({
        pickup_in_store: listing_obj.pickup_in_store_details[:eligible_for_pickup_in_store],
        click_collect_collection_available: listing_obj.pickup_in_store_details[:eligible_for_pickup_drop_off]
      }.reject { |_k, v| v.blank? })
    end
  end

  def sync_price(listing_obj, variant)
    # For weird scenario where main variant doesn't have an associated eBay price
    unless (local_price = variant.ebay_price)
      local_price = variant.build_ebay_price
    end

    price_hash = { with_tax: listing_obj.current_price }
    price_hash[:tax_rate] = 0 if C.ex_vat && listing_obj.current_price < Money.new(C.ex_vat_threshold, listing_obj.current_price.currency)

    local_price.update(price_hash)
    variant.retail_price.update(price_hash) if variant.retail_price.with_tax.zero?
  end

  def sync_returns_policy(listing_obj, channel)
    if listing_obj.returns_policy
      channel.update({
        restocking_fee_value_option: listing_obj.returns_policy[:restocking_fee_value_option],
        returns_description: listing_obj.returns_policy[:description],
        returns_within: listing_obj.returns_policy[:returns_within_option],
        returns_cost_paid_by: listing_obj.returns_policy[:shipping_cost_paid_by_option],
        refund_option: listing_obj.returns_policy[:refund_option]
      }.reject { |_k, v| v.blank? })
    end
  end

  def sync_ship_to_locations(listing_obj, channel)
    ship_tos = if listing_obj.international_options && (int_shipping = to_array(listing_obj.international_options).first)
                 int_shipping[:ship_to_location]
               else
                 listing_obj.default_ship_tos
               end
    to_array(ship_tos)&.each do |ship_to|
      channel.ship_to_locations.find_or_create_by(location: C::Product::Channel::Ebay::ShipToLocation.code_to_location(ship_to)) unless C::Product::Channel::Ebay::ShipToLocation.code_to_location(ship_to) == ''
    end
  end

  def sync_warranty(listing_obj, channel)
    if listing_obj.returns_policy && listing_obj.returns_policy[:warranty_offered].present? && listing_obj.returns_policy[:warranty_duration].present?
      channel.update(warranty_offered: true,
                     warranty_duration: listing_obj.returns_policy[:warranty_duration],
                     warranty_type: listing_obj.returns_policy[:warranty_type_option])
    else
      channel.update(warranty_offered: false)
    end
  end

  def sync_weight(listing_obj, channel)
    if (details = listing_obj.package_details) &&
       details[:weight_major_measurement_system] == 'Metric'
      channel.master
             .main_variant
             .update(weight: listing_obj.package_details[:weight_major])
    end
  end

  def sync_ebay_sku(listing_obj, variant)
    return if listing_obj.sku == variant.sku
    if listing_obj.sku.present?
      variant.update(ebay_sku: listing_obj.sku)
    else
      return unless Ebay::Listing.instance_methods.include? :body_sku
      if C.ebay_sku_from_body && listing_obj.body_sku.present? && listing_obj.body_sku != variant.sku
        variant.update(ebay_sku: listing_obj.body_sku)
      end
    end
  end

  def sync_store_categories(listing_obj, master)
    return unless listing_obj.has_store_front?
    if listing_obj.store_category_id && ( category = C::Category.find_by(ebay_store_category_id: listing_obj.store_category_id) )
      master.categorise(category)
    end
    if listing_obj.store_category2_id && ( category = C::Category.find_by(ebay_store_category_id: listing_obj.store_category2_id) )
      master.categorise(category)
    end
  end

  def sync_status(variant)
    variant.inactive! if C.ebay_status_sync && variant.current_stock < 1
  end

end
