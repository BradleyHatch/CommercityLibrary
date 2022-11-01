# frozen_string_literal: true

require 'nokogiri'

module C
  module Product
    module Channel
      class Ebay < ApplicationRecord
        include C::Channel
        include C::ChannelOrderable

        CONDITIONS = [
          ['brand_new', 1000],
          ['new_other', 1500],
          ['new_with_defects', 1750],
          ['manufacturer_refurbished', 2000],
          ['seller_refurbished', 2500],
          ['like_new', 2750],
          ['used', 3000],
          ['very_good', 4000],
          ['good', 5000],
          ['acceptable', 6000],
          ['for_parts_not_working', 7000]
        ].freeze

        belongs_to :classifier_property_key, class_name: 'C::Product::PropertyKey', optional: true
        belongs_to :ebay_category, class_name: 'C::EbayCategory'
        belongs_to :delivery_service, class_name: 'C::Delivery::Service'
        belongs_to :international_shipping_service,
                   class_name: 'C::Delivery::Service'

        has_many :ship_to_locations,
                 class_name: 'C::Product::Channel::Ebay::ShipToLocation',
                 dependent: :destroy
        accepts_nested_attributes_for :ship_to_locations,
                                      allow_destroy: true,
                                      reject_if: :invalid_ship_to?

        has_many :feature_images,
                 class_name: 'C::Product::Channel::Ebay::FeatureImage',
                 dependent: :destroy

        has_many :shipping_services,
                 class_name: 'C::Product::Channel::Ebay::ShippingService',
                 dependent: :destroy
        accepts_nested_attributes_for :shipping_services,
                                      allow_destroy: true,
                                      reject_if: ->(val) { val[:delivery_service_id].blank? }

        def is_valid?
          category_id.present?
        end

        # returns the ebay category default id if the attribute is blank for
        # ebay channel
        def category_fallback
          categories = master.categories.where.not(ebay_category_id: nil)
          categories.first.ebay_category.category_id
        rescue NoMethodError
          ebay_category&.category_id
        end

        def last_push_success
          if C::Setting.get(:ebay_sync)
            master.main_variant.ebay_last_push_success
          else
            master.main_variant.item_id.present?
          end
        end

        def set_to_inactive
          return unless duration == 'GTC'
          C::EbayJob.perform_later('make_listings_inactive', obj: master)
        end

        def set_to_active
          C::EbayJob.perform_later('make_listings_active', obj: master)
        end

        def auto_push
          push_to_ebay
        end

        def push_to_ebay
          C::EbayJob.perform_later('add_or_revise_variants', obj: master)
        end

        def invalid_ship_to?(location)
          if ship_to_locations.pluck(:location).include? location[:location]
            return true
          end
          true if location[:location].blank?
        end

        def error_logs(call)
          logs = master.main_variant.ebay_last_push_body
          if logs['errors'].present?
            result = "#{master.main_variant.name} wasn't #{call}."
            result += ', check the eBay activity tab for more info. Errors: '
            logs['errors'].each_with_index do |error, i|
              result += error['long_message']
              result += ', ' unless logs['errors'].length == i + 1
            end
          else
            result = "#{master.main_variant.name} was #{call}"
          end
          result
        end

        def payment_method_evaluate(method)
          case method
          when 'PayPal'
            { payment_method_paypal: true }
          when 'Escrow'
            { payment_method_escrow: true }
          when 'CCAccepted'
            { payment_method_cc: true }
          when 'CreditCard'
            { payment_method_cc: true }
          when 'PersonalCheck'
            { payment_method_cheque: true }
          when 'PostalTransfer'
            { payment_method_postal: true }
          when 'MOCC'
            { payment_method_money_order: true }
          else
            {}
          end
        end

        #### Returning data for channel tab select fields ####
        def domestic_types
          %i[Calculated
             CalculatedDomesticFlatInternational
             Flat
             FlatDomesticCalculatedInternational
             Free
             Freight
             FreightFlat
             NotSpecified]
        end

        def durations
          [:GTC]
        end

        def retrieve_shop_wrap
          return shop_wrap if shop_wrap.present?
          C::Product::Wrap.first&.wrap
        end

        # Subs out the wrap tags with calls to ebay channel methods
        # This will get pushed to eBay
        # This is a bit hacky now because it takes param and then has to
        # do a comparison when before it was just doing straight send and using
        # eBay body, now uses title fallback method from variant.rb
        def subbed_shop_wrap(body, price=nil)
          return body if (subbed_wrap = retrieve_shop_wrap).blank?

          tags = {
            'PRODUCT_LISTING_TITLE' => ['name'],
            'PRODUCT_LISTING_PRICE' => ['shop_wrap_price', price],
            'PRODUCT_DESCRIPTION' => ['shop_wrap_text', body],
            'PRODUCT_TEXT_1' => ['shop_wrap_text', wrap_text_1],
            'PRODUCT_TEXT_2' => ['shop_wrap_text', wrap_text_2],
            'PRODUCT_FEATURES' => ['shop_wrap_features'],
          }

          tags.each do |tag, args|
            method, argument = args
            value = if args.length > 1
                      send(method, argument)
                    else
                      send(method)
                    end

            if value.present?
              subbed_wrap = subbed_wrap.gsub("[{#{tag}}]", value)
            else
              regex = /<!-- block #{tag} -->(.*)\<!-- endblock #{tag} -->/m
              subbed_wrap = subbed_wrap.gsub(regex, '')
            end
          end
          subbed_wrap = subbed_wrap_images(subbed_wrap)
          subbed_related_products(subbed_wrap)
        end

        # Returns text wrapped in divs for easy gsubbing
        def shop_wrap_text(text)
          return '' if text.blank?
          "<div class='gsub-start'></div>#{text}<div class='gsub-end'></div>"
        end

        # Returns text wrapped in divs for easy gsubbing
        def shop_wrap_price(text)
          "<strong>#{text}</strong>"
        end

        # builds the product features section in the ebay wrap based on
        # selected product features and feature images
        def shop_wrap_features
          features = master.main_variant.product_features.ordered.map { |m| m.feature.get_content }
          
          images = feature_images.ordered.map do |m| 
            next if m.image.blank? || m.image.image.blank? || m.image.image.url.blank?
            "<img src='#{m.image.image.url}'/>"
          end.compact

          rows = ''
          count = 0
          (features + images).each do |url|
            rows += C.wrap_features_container if count.zero?
            rows += "#{C.wrap_features_row}#{url}#{C.wrap_features_end}"
            count += 1
            if count == 2 || (count.odd? && (features + images).last == url)
              count = 0
              rows += C.wrap_features_end.to_s
            end
          end
          rows
        end

        # Replaces image tags with image urls if a channel has images
        def subbed_wrap_images(subbed_wrap)
          images = %w[
            [{PRODUCT_IMAGE_1}]
            [{PRODUCT_IMAGE_2}]
            [{PRODUCT_IMAGE_3}]
            [{PRODUCT_IMAGE_4}]
          ]

          image_collection.each_with_index do |image, i|
            break if i == images.length
            image.is_a?(C::Product::Image) ? image_url = image.image.url : image_url = image.image.image.url
            subbed_wrap = subbed_wrap.gsub(images[i], image_url)
          end

          subbed_wrap
        end

        def subbed_related_products(subbed_wrap)
          related_products = wrap_related_products

          tags = %w[
            [{PRODUCT_RELATED_#_LINK}]
            [{PRODUCT_RELATED_#_NAME}]
            [{PRODUCT_RELATED_#_IMAGE}]
          ]

          related_products.each_with_index do |p, i|
            next if p.blank?

            tags.each_with_index do |tag, j|
              next if p[j].blank?
              subbed_tag = tag.gsub('#', (i+1).to_s)
              subbed_wrap = subbed_wrap.gsub(subbed_tag, p[j])
            end

          end

          subbed_wrap
        end

        # Meant to be used with body string from hash returned from ebay after
        # a wrap has been pushed. Strips out everything from
        # before and after the wrapper divs
        def subbed_text(ebay_body)
          parsed_body = Nokogiri::HTML::DocumentFragment.parse(ebay_body).to_html
          matches = parsed_body.scan(/((?<=(<div class=("|')gsub-start("|')><\/div>))(.*?)(?=(<div class=("|')gsub-end("|')><\/div>)))+/m)
          if matches.length > 0
            matches.map { |m| m[0] }
          else
            parsed_body
          end
        end


        def wrap_related_products
          related_products = master.related_products.take(3)
          added_ids = []

          related_products.map do |p|
            if p.item_id.blank?
              p = C::Product::Variant.where.not(id: related_products.pluck(:id)+added_ids).where.not(item_id: nil).where(status: :active).first
              added_ids << p.id unless p.blank?
            end

            next if p.blank?

            [
              "http://cgi.ebay.co.uk/ws/eBayISAPI.dll?ViewItem&item=#{p.item_id}",
              p.name,
              p.ebay_channel.channel_images.ordered.first&.image&.image&.url,
            ]
          end
        end

        def domestic_services
          shipping_services.where(international: false)
        end

        def international_services
          shipping_services.where(international: true)
        end

        def get_domestic_services
          arr = shipping_services.where(international: false)
          arr.empty? ? [shipping_services.build(international: false)] : arr
        end

        def get_international_services
          arr = shipping_services.where(international: true)
          arr.empty? ? [shipping_services.build(international: true)] : arr
        end

        def get_ship_to_locations
          arr = ship_to_locations
          arr.empty? ? [ship_to_locations.build] : arr
        end

        def image_collection
          channel_images.any? ? channel_images.ordered : master.images
        end

        ########

        ########################################################################
        #### bunch of methods for setting fields default values for form, see
        # c.rb ####
        ########################################################################
        def default_start_price
          return unless start_price.blank? || start_price.fractional < 99
          master.main_variant.web_price if C.ebay_start_price == :web_price
        end

        def default_postcode
          postcode.blank? ? C.ebay_postcode : postcode
        end

        def default_duration
          duration.blank? ? C.ebay_duration : duration
        end

        def default_payment_paypal
          if payment_method_paypal.blank?
            C.ebay_payment_paypal
          else
            payment_method_paypal
          end
        end

        def default_dispatch_days
          if dispatch_time.blank?
            C.ebay_dispatch_days
          else
            dispatch_time
          end
        end

        def default_shipping_type
          if domestic_shipping_type.blank?
            C.ebay_shipping_type
          else
            domestic_shipping_type
          end
        end

        def default_shipping_collect
          if pickup_in_store.blank?
            C.ebay_shipping_collect
          else
            pickup_in_store
          end
        end

        def default_returns_accepted
          if returns_accepted.blank?
            C.ebay_returns_accepted
          else
            returns_accepted
          end
        end
      end
    end
  end
end
