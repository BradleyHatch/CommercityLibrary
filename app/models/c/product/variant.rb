# frozen_string_literal: true

module C
  module Product
    class Variant < ApplicationRecord
      include PgSearch

      include Pageinfoable
      include Sluggable
      include Priceable

      # SCOPES
      #
      # Published:
      # Marks whether something is allowed to be published
      # Currently, must be an active product, have a name and not be
      # discontinued to appear in lists.
      # Passing in a channel name returns that channels published items.
      scope :published, (lambda { |channel=nil|
        able = where.not(name: ['', nil]).active.where(discontinued: false)
        channel ? able.where("published_#{channel}".to_sym => true) : able
      })
      
      # Featured:
      # Any items which have been selected as featured
      scope :featured, (-> { where(featured: true) })

      # Latest in:
      # These are the most recent products on the store which have been
      # published on the web
      scope :latest_in, (-> { order(created_at: :desc).first(12) })

      # In stock first:
      # Sort by stock descending
      scope :in_stock_first, (-> { order(current_stock: :desc) })

      # In Stock
      scope :in_stock, (-> { where('current_stock > 0') })

      # Featured First:
      # whole list but with featured items first
      scope :featured_first, (-> { order(featured: :desc) })

      # Main app display:
      # Call on any product list display to more efficiently grab joins etc
      scope :for_display, (lambda {
        where(display_in_lists: true).sellable
      })

      scope :sellable, (lambda {
        published(:web).includes(:master, :web_channel)
      })

      # On Sale (web channel):
      # Products with a discount price which is lower than the web price
      scope :on_sale, -> {
        includes(:web_channel)
        .where.not(c_product_channel_webs: {discount_price_pennies: [nil, 0]})
        .where('c_product_channel_webs.discount_price_pennies > cache_web_price_pennies')
      }

      scope :best_sellers, -> {
        left_joins(:order_items)
        .group(:id)
        .order('COUNT(c_order_items.id) DESC')
      }

      # Front-end search
      # Uses pg_search to perform a Postgres Full Text search. It's possible to
      # search through immediate associations (including has_x through ones),
      # but not nested ones.
      pg_search_scope(
        :full_text_search,
        against: [
          [:sku, 'A'],
          [:name, 'B'],
          [:oe_number, 'C']
        ],
        associated_against: {
          web_channel: %i[name description sub_title],
          categories: %i[name],
          brand: %i[name],
          manufacturer: %i[name]
        },
        using: {
          tsearch: {
            prefix: true,
            any_word: true
          }
        }
      )

      # ENUMS
      enum status: %i[active inactive]
      enum product_tag: ['B-Stock', 'Regular', 'Sale', 'Used', 'Stocks',
                         'Low stock']

      # ASSOCIATIONS
      belongs_to :master
      belongs_to :country_of_manufacture, class_name: 'Country'
      belongs_to :cache_image, class_name: 'C::Product::Image'
      belongs_to :image_variant, class_name: 'C::Product::Variant'

      has_one :web_channel, through: :master
      has_one :ebay_channel, through: :master
      has_one :amazon_channel, through: :master
      has_one :brand, through: :master
      has_one :manufacturer, through: :master


      has_many :web_channel_images, through: :web_channel, source: :channel_images
      has_many :web_channel_images_images, through: :web_channel_images, source: :image
      has_many :ebay_channel_images, through: :ebay_channel, source: :images
      has_many :amazon_channel_images, through: :amazon_channel, source: :images
      has_many :categories, through: :master
      has_many :variant_images
      has_many :images, through: :variant_images
      has_many :property_values, dependent: :destroy
      has_many :property_keys, through: :property_values
      has_many :barcodes, dependent: :destroy, inverse_of: :variant
      has_many :price_matches, dependent: :destroy, class_name: 'C::Product::PriceMatch', inverse_of: :variant
      has_many :variants, through: :master
      has_many :bundle_items
      has_many :bundled_variants, through: :bundle_items
      has_many :questions
      has_many :offers
      has_many :option_variants, dependent: :destroy
      has_many :options, through: :option_variants
      has_many :variant_vouchers, dependent: :destroy
      has_many :vouchers, through: :variant_vouchers
      has_many :product_features,  class_name: 'C::Product::ProductFeature'
      has_many :features, :through => :product_features
      has_many :service_variants, class_name: 'C::Delivery::ServiceVariant', dependent: :destroy
      has_many :services, through: :service_variants
      has_many :order_items, class_name: "C::Order::Item", foreign_key: "product_id"
      has_many :collection_variants, class_name: 'C::CollectionVariant', dependent: :destroy
      has_many :collections, through: :collection_variants, class_name: 'C::Collection'
      has_many :variant_dimensions, dependent: :destroy

      accepts_nested_attributes_for :property_values, allow_destroy: true, reject_if: ->(val) { val[:value].blank? }
      accepts_nested_attributes_for :bundle_items, allow_destroy: true
      accepts_nested_attributes_for :barcodes, allow_destroy: true, reject_if: ->(val) { val[:value].blank? }
      accepts_nested_attributes_for :price_matches, allow_destroy: true
      accepts_nested_attributes_for :variant_dimensions, allow_destroy: true
      accepts_nested_attributes_for :features

      has_and_belongs_to_many :amazon_processing_queues, class_name: 'C::AmazonProcessingQueue', foreign_key: 'product_id', join_table: 'c_apqs_products'

      # VALIDATIONS
      validates :sku, presence: true, length: { maximum: 40 }
      validates :mpn, length: { maximum: 40 }
      validates :retail_price, presence: true
      validates :delivery_override, numericality: { less_than: 100 }
      validates :info, exclusion: [nil]

      validate :ensure_sku_uniqueness

      validates :name, :mpn, presence: true, if: -> do
        ENV['USE_AMAZON_PRODUCT_PIPELINE'] && published_amazon
      end
      
      before_validation { build_retail_price if retail_price.blank? }
      
      before_validation { 
        if sku.present?
          sku.strip!
        end
      }
      

      after_save do
        build_cache_fields
        if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
          self.update_columns(should_push_to_amazon_pipeline: true)
        end
      end

      after_destroy { sibling_variants&.first&.update!(main_variant: true) }

      has_paper_trail if: proc { PaperTrail.whodunnit.present? }

      # MONEY MONEY
      monetize :cost_price_pennies
      monetize :rrp_pennies
      monetize :delivery_override_pennies
      monetize :cache_web_price_pennies
      monetize :cache_amazon_price_pennies
      monetize :cache_ebay_price_pennies

      has_price :retail_price
      has_price :web_price
      has_price :amazon_price
      has_price :ebay_price

      def options_are_changing_but_they_on_a_cart options_id_next
        options_ids_was = options.pluck(:id)

        options_ids_removed = options_ids_was - options_id_next

        options_are_invalid = false

        if options_ids_removed.any?
          option_variants = C::Product::OptionVariant.where(option_id: options_ids_removed, variant_id: self.id)
          option_variant_on_a_cart = option_variants.find { |option_variant| option_variant.cart_item_option_variants.any? }
          if option_variant_on_a_cart.present?
            options_are_invalid = true
          end
        end

        options_are_invalid
      end

      # Called by the validation above
      # Ensures the SKUs are unique ignoring whitespace
      def ensure_sku_uniqueness
        return if sku.nil?
        if (variant = C::Product::Variant.find_by(sku: sku.strip))
          errors.add(:sku, 'has already been taken') unless variant.id == id
        else
          sku.strip!
        end
      end

      # If given a barcode type (type = symbology), finds the first barcode of
      # that type. Otherwise, finds the first barcode or nil.
      def barcode(params={})
        if (given_symbology = params.delete(:symbology))
          barcodes.find_by(symbology: given_symbology)
        else
          barcodes.first
        end
      end

      def barcode_does_not_apply_text
        C::EbayJob.perform_now('set_unavailable_text') if C::Setting.get('ebay_unavailable').blank?
        C::Setting.get('ebay_unavailable')
      end

      def weight
        unless C.multiple_package_dimensions
          return super
        end

        if variant_dimensions.empty?
          0.0
        end

        variant_dimensions.pluck(:weight).sum
      end

      def in_stock?
        current_stock&.positive?
      end

      def values_for_property_key(key)
        property_values.where(property_key: key)
      end

      def display_thumbnail
        if images.any?
          images&.ordered&.first&.image&.thumbnail
        elsif image_variant.present?
          image_variant&.images&.ordered&.first&.image&.thumbnail
        else
          master.display_thumbnail
        end
      end 

      def table_name
        "<b>#{sku}</b>
        <br>
        #{(name || '')[0..80]}
        #{main_variant ? "" : "<br><span style='color: #2D3138'>(variant of: #{master.main_variant.sku})</span>"}
        "
      end

      def table_categories
        categories.pluck(:name).join(', ')
      end      

      def name_with_value(key_string)
        key = C::Product::PropertyKey.find_by(key: key_string)
        return name unless key
        value = values_for_property_key(key)&.first&.value
        "#{name} #{value}"
      end

      def sibling_variants
        master.variants.where.not(id: id)
      end

      def sibling_variants_with_images
        sibling_variants.left_joins(:variant_images).where('c_product_variant_images.variant_id = c_product_variants.id').group(:id)
      end

      def displaying_image_variant_images?
        images.empty? && image_variant.present?
      end

      def sku_and_name
        "#{sku} - #{name}"
      end

      # Returns the first image for the product - takes optional style
      def primary_web_image(style='product_standard')
        primary_image&.send(style) || 'placeholder.png'
      end

      def primary_image
        primary_image_record&.image
      end

      def primary_image_record
        image = if images.any?
                  images&.ordered&.first
                elsif image_variant.present?
                  image_variant&.images&.ordered&.first
                else
                  web_channel&.channel_images&.ordered&.first&.image
                end
        image || master&.images&.order(id: :asc).first
      end

      # Returns the image collection of the product takes optional channel
      def image_collection(channel=nil)
        return images.ordered.map(&:image) if images.any?
        return image_variant.images.ordered.map(&:image) if image_variant.present? && image_variant.images.any?
        main_image_collection(channel)
      end

      def main_image_collection(channel=nil)
        if channel && send("#{channel}_channel").images.any?
          send("#{channel}_channel").images.ordered.reverse.map(&:image)
        else
          master.images.order(id: :asc).map(&:image)
        end
      end

      # Used to build the variants form
      def build_nested_elements
        retail_price || build_retail_price
        web_price    || build_web_price
        ebay_price   || build_ebay_price
        amazon_price || build_amazon_price
      end

      def finance_eligible?
        price(channel: :web).to_i * 0.9 > 250
      end

      def minimum_monthly_finance
        price(channel: :web) * 0.9 / 36
      end

      # Prices
      # Still a little ugly, but functionally sufficient. Gracefully tries to
      # find a non-zero price.
      def price(channel: nil, fallback: nil, tax: true)
        requested_price = price_object(channel: channel, fallback: fallback)
        return Money.new(0) unless requested_price
        requested_price.send(tax ? :with_tax : :without_tax)
      end

      def tax_rate(channel: nil, fallback: nil)
        requested_price = price_object(channel: channel, fallback: fallback)
        requested_price&.tax_rate
      end

      def price_object(channel: nil, fallback: nil)
        channels = [channel, fallback, :retail].compact

        last_price = nil
        channels.each do |ch|
          last_price = send("#{ch}_price")
          return last_price unless last_price.nil? || last_price.zero?
        end

        return last_price if main_variant
        master&.main_variant&.price_object(channel: :web)
      end

      def tax(opts = {})
        price(opts.merge(tax: true)) - price(opts.merge(tax: false))
      end

      # This grabs all of the urls for the product images and returns a string
      # split with commas for the CSV importer
      def master_image_links
        image_links = ''
        if master.images.any?
          master.images.each do |image|
            image_links += if image == master.images.last
                             image.image.url
                           else
                             "#{image.image.url}, "
                           end
          end
        end
        image_links
      end

      # Used for pushing 0 stock to ebay if the variant is inactive or not published
      def quantity_check
        inactive? || !published_ebay ? 0 : ebay_stock
      end

      # Checks if a max_stock limit has been set on the ebay channel and defaults to current_stock
      def ebay_stock
        if ebay_channel.max_stock.present? && ebay_channel.max_stock > 0 && current_stock >= ebay_channel.max_stock
          ebay_channel.max_stock
        else
          current_stock >= 0 ? current_stock : 0
        end
      end

      # Updates the boolean based on respons acknowledgement recieved from eBauy
      def update_push_status(response_hash)
        if response_hash['ack'] == 'Failure'
          update(ebay_last_push_success: false)
        elsif response_hash['ack'] == 'Success' ||
              response_hash['ack'] == 'Warning'
          update(ebay_last_push_success: true)
        end
      end

      def amazon_last_push_success
        return nil if amazon_channel.last_push_success.nil?
        !amazon_channel.last_push_success
      end

      # Loops through ebay response hash and splits issues/errors from last push
      def update_push_body(response_hash)
        json = {}
        json['status'] = response_hash['ack']
        json['errors'] = []
        json['issues'] = []

        response_hash['errors']&.each do |error|
          if error['severity_code'] == 'Error'
            json['errors'] << error
          else
            unless error['long_message'] ==
                   'The Return Policy field Refund in the input has been ignored.'
              json['issues'] << error
            end
          end
        end
        update(ebay_last_push_body: json)
      end

      # Returns ebay_channel name if main variant else returns variant name
      # Will be removed whenever variants have there own ebay channel
      def ebay_title_fallback
        main_variant? ? ebay_channel.name : name
      end

      # Various fallbacks for pushing descriptions to ebay
      def ebay_override_body
        if respond_to? :ebay_body
          ebay_body
        elsif description.blank?
          if ebay_channel.body.blank?
            web_channel.description
          else
            ebay_channel.body
          end
        else
          description
        end
      end

      def ebay_sku
        self[:ebay_sku].blank? ? sku : self[:ebay_sku]
      end

      # Better fallback than above for when pushing variants to eBay etc. etc.
      def channel_description_fallback(channel, fallback='web')
        return description unless main_variant || description.blank?
        return send("#{channel}_channel").description if send("#{channel}_channel").description.present?
        return send("#{fallback}_channel").description if send("#{fallback}_channel").description.present?
        description
      end

      def property(key)
        property_values.includes(:property_key).where(
          'c_product_property_keys.key = ?', key
        ).references(
          :c_product_property_keys
        ).first
      end

      def properties
        values = property_values
          .joins(:property_key)
          .select('*, c_product_property_keys.key as key_name')
        values.to_a.pluck(:key_name, :value).to_h
      end

      def property_tree(filter_list = %w[Colour Size])
        group_properties(filter_list.shift, filter_list,
                         variants.where(published: true, published_web: true,
                                        discontinued: false))
      end

      def group_properties(key, filter_list, set)
        output_hash = {}
        pk = C::Product::PropertyKey.find_by(key: key)
        set.each do |item|
          if (pv = item.property_values.find_by(property_key: pk))
            if filter_list.any?
              output_hash[pv.value] ||= []
              output_hash[pv.value].append(item)
            else
              output_hash[pv.value] ||= { slug: item.slug }
            end
          else
            return { slug: item.slug }
          end
        end
        unless output_hash.key?(:slug)
          new_key = filter_list.shift
          output_hash.each do |value, items|
            next if items.key?(:slug) rescue false
            output_hash[value] = group_properties(new_key, filter_list, items)
          end
        end
        output_hash
      end

      # Define default columns for textacular to search
      def self.searchable_columns
        [:name, :sku]
      end

      def web_channel_images_with_fallback
        web_channel_images.any? ? web_channel.images : master.images
      end

      def on_sale?
        return false if web_channel.discount_price.blank? || web_channel.discount_price.zero?
        web_channel.discount_price > price(channel: :web)
      end

      def sale_saving
        web_channel.discount_price - price(channel: :web)
      end

      def info=(args)
        corrected_hash = {}
        args.each do |key, value|
          key = key.to_sym
          field_type = C.product_info_fields.dig(key, :type)
          corrected_hash[key] = if field_type == :boolean
                                  value == '1'
                                else
                                  value
                                end
        end
        super(corrected_hash)
      end

      def build_cache_fields
        return if master&.new_record?
        build_cache_web_price
        build_cache_ebay_price
        build_cache_amazon_price
        build_cache_main_image
      end

      def build_cache_web_price
        return if cache_web_price == price(channel: :web)
        update(cache_web_price: price(channel: :web))
      end

      def build_cache_ebay_price
        return if cache_ebay_price == price(channel: :ebay, fallback: :web)
        update(cache_ebay_price: price(channel: :ebay, fallback: :web))
      end

      def build_cache_amazon_price
        return if cache_amazon_price == price(channel: :amazon, fallback: :web)
        update(cache_amazon_price: price(channel: :amazon, fallback: :web))
      end

      def build_cache_main_image
        primary_image_id = primary_image_record&.id
        cache_image_id = cache_image&.id
        return if primary_image_id == cache_image_id
        update(cache_image: primary_image_record)
      end

      def display_only
        if main_variant
          super
        else
          sibling_variants.find_by(main_variant: true)&.display_only
        end
      end

      def self.text_search(term)
        search_stuff = {
          c_product_variants: %i[sku name oe_number],
          c_product_channel_webs: %i[name description sub_title],
          c_brands: %i[name],
          manufacturers_c_product_variants: %i[name],
          c_categories: %i[name],
          c_product_property_values: %i[value],
        }

        term = "%#{term.strip.gsub("'", "")}%"

        condition = search_stuff.map { |table, cols| cols.map { |col| %(replace("#{table}"."#{col}", '''', '') ILIKE :term) } }.join(' OR ')

        where(id:
          unscoped.left_joins(
            :web_channel, 
            :brand, 
            :manufacturer, 
            :categories,
            :property_values,
          ).where(condition, term: term).select(:id)
        )
      end

    end
  end
end
