
# frozen_string_literal: true

module C
  module Product
    class Master < ApplicationRecord
      include Documentable

      enum condition: C.product_conditions

      scope :published, -> { includes(:main_variant).where(c_product_variants: { status: 0, discontinued: false }) }
      scope :web_products, -> { includes(:variants).where(c_product_variants: { published_web: true }) }
      scope :ebay_products, -> { includes(:variants).where(c_product_variants: { published_ebay: true }) }
      scope :amazon_products, -> { includes(:variants).where(c_product_variants: { published_amazon: true }) }
      scope :featured, -> { includes(:main_variant).where(c_product_variants: { featured: true }) }

      scope :with_includes, lambda {
        eager_load(
          %i[
             brand manufacturer categories amazon_channel
          ], main_variant: :cache_image
        )
      }

      scope :with_main_variant, lambda {
        eager_load(
          %i[
            main_variant
          ]
        )
      }

      # channels tell the master how the product should be presented on each platform
      # - if it has a different name or description
      # - what images relate to it
      has_one :amazon_channel, class_name: 'C::Product::Channel::Amazon', dependent: :destroy
      has_one :ebay_channel, class_name: 'C::Product::Channel::Ebay', dependent: :destroy
      has_one :web_channel, class_name: 'C::Product::Channel::Web', dependent: :destroy
      accepts_nested_attributes_for :web_channel, :amazon_channel, :ebay_channel
      validates :web_channel, :ebay_channel, :amazon_channel, presence: true
      has_many :web_channel_images, through: :web_channel, source: :channel_images
      has_many :web_channel_images_images, through: :web_channel_images, source: :image

      # variants define custom attributes such as barcode, sku, color, etc whilst maintaining the
      # same channels and thus the same description and images and overall look
      has_many :variants, autosave: true, dependent: :destroy
      accepts_nested_attributes_for :variants

      # the main_variant determines all default values which havent been specified on individual
      # variants. For instance if all variants had the same weight then you could omit this attribute
      # and define it once on the main_variant.
      # belongs_to :main_variant, class_name: 'C::Product::Variant', dependent: :destroy, autosave: true
      has_one :main_variant, -> { where(main_variant: true) }, class_name: 'C::Product::Variant', dependent: :destroy, autosave: true
      accepts_nested_attributes_for :main_variant
      # validates :main_variant, presence: true

      has_one :web_price, through: :main_variant
      has_one :amazon_price, through: :main_variant
      has_one :ebay_price, through: :main_variant
      has_one :retail_price, through: :main_variant

      has_many :categorizations, dependent: :destroy, foreign_key: :product_id
      accepts_nested_attributes_for :categorizations
      has_many :categories, through: :categorizations

      has_many :property_values, through: :main_variant
      delegate :property, to: :main_variant

      belongs_to :brand
      accepts_nested_attributes_for :brand
      belongs_to :manufacturer, class_name: 'C::Brand'
      accepts_nested_attributes_for :manufacturer

      has_many :images, dependent: :destroy
      accepts_nested_attributes_for :images, allow_destroy: true, reject_if: ->(img) { img[:image].blank? && img[:image_cache].blank? }

      has_many :amazon_processing_queues, through: :variants

      validate :amazon_validations

      validates :brand, presence: true, if: -> do
        ENV['USE_AMAZON_PRODUCT_PIPELINE'] && main_variant&.published_amazon
      end

      before_save do
        # This decodes the HTML entities ensuring they will parse to xml & others more reliably
        require 'htmlentities'
        text_areas = { 'web_channel' => 'description', 'ebay_channel' => 'description', 'amazon_channel' => 'description' }
        text_areas.each do |name, record|
          coder = HTMLEntities.new
          string = send(name)[record]
          decoded = coder.decode(string).gsub(/(&(?!amp;))/, '&amp;')
          send(name).update(record => decoded)
        end
      end

      before_validation do
        # build channels
        build_amazon_channel if amazon_channel.blank?
        build_ebay_channel if ebay_channel.blank?
        build_web_channel if web_channel.blank?
      end

      has_many :product_relations, foreign_key: :product_id
      has_many :related_products, through: :product_relations, source: :related
      accepts_nested_attributes_for :product_relations, allow_destroy: true

      has_many :add_on_products, foreign_key: :main_id
      has_many :add_ons, through: :add_on_products, source: :add_on
      accepts_nested_attributes_for :add_on_products, allow_destroy: true

      delegate :name, :description, :sku, :property_values, :price, :retail_price, :web_price, :ebay_price, :amazon_price, :featured, to: :main_variant
      delegate :title=, :meta_description=, :meta_keywords=, to: :main_variant

      scope :archived, -> { includes(:main_variant).where(c_product_variants: { discontinued: true }) }

      attr_accessor :new_images
      attr_accessor :remote_image_array

      def local_ebay_validate
        errors = []

        ebay_variants = variants.where(published_ebay: true)
        is_a_variants_listing = ebay_variants.size > 1

        if ebay_channel.category_fallback.blank?
          errors.push("No eBay category assigned. Please assign a leaf category using the category select lists on the eBay tab")
        end


        if is_a_variants_listing
          variants_have_same_properties = true
          ebay_variant_property_keys = []

          ebay_variants.each do |ev|
            if ev.properties.keys.empty?
              variants_have_same_properties = false
              break
            end

            if ebay_variant_property_keys.empty?
              ebay_variant_property_keys = ev.properties.keys.sort
              next
            end

            if ebay_variant_property_keys != ev.properties.keys.sort
              variants_have_same_properties = false
              break
            end
          end

          if !variants_have_same_properties
            errors.push("Variants published for eBay do not have matching sets of properties. Ensure each variant has the same set of properties.")
          end
        end

        update_attributes(ebay_local_errors: errors)

        return errors.size.zero?
      end

      def related_products(limit=4)
        related_master_ids = super.ids

        related = C::Product::Variant.where(
          main_variant: true, master_id: related_master_ids
        ).order('RANDOM()').for_display.active.limit(limit)

        related = related.in_stock if C.hide_zero_stock_products

        category_master_ids = C::Product::Categorization
          .where(category_id: category_ids)
          .where.not(product: self.id)
          .pluck(:product_id)

        from_category = C::Product::Variant.where(master_id: category_master_ids)
                                           .order('RANDOM()')
                                           .for_display
                                           .active
                                           .limit(limit - related.count)
                                           
        from_category = from_category.in_stock if C.hide_zero_stock_products

        random = C::Product::Variant.where.not(id: related.ids + from_category.ids)
                                    .order('RANDOM()')
                                    .for_display
                                    .active
                                    .limit(limit - (related.count + from_category.count))
        random = random.in_stock if C.hide_zero_stock_products
        related + from_category + random
      end

      def set_related_from_csv(csv, ids, relation='product_relations', key='related_id')
        split_csv = csv.split(',')
        current_relations = []
        split_csv.each do |sku|
          variant = C::Product::Variant.find_by(sku: sku.strip)
          current_relations << send(relation).find_or_create_by(key => variant.master.id) if variant
        end
        send(relation).each do |pr|
          pr.destroy if !current_relations.include?(pr) && !ids.include?(pr.send(key)).to_s
        end
      end

      def generate_related_csv(relation='product_relations', key='related')
        skus = send(relation).map do |pr|
          pr.send(key).main_variant.sku
        end
        skus.join(', ')
      end

      def new_images=(val)
        image_attrs = val.map { |image| { image: image } }
        self.images_attributes = image_attrs
      end

      def remote_image_array=(images_string)
        return unless images_string
        images_string = images_string.gsub(/\s/, '')

        remote_urls = remote_image_urls.map { |url| url.gsub(/\s/, '') }
        remote_names = remote_urls.map do |image|
          parts = image.split('/')
          parts.last
        end
        
        last_img = web_channel&.channel_images&.ordered&.last
        weight = last_img.present? ? last_img.weight : 0

        images_string.split(',').map do |image|
          parts = image.split('/')
          filename = parts.last

          next if remote_names.include?(filename)

          new_img = images.build(remote_image_url: image)

          if web_channel
            new_web_img = web_channel.channel_images.build(image: new_img, weight: weight) 
            weight += 1
          end
        end
      end

      def remote_image_urls
        images.map { |image| image.image.url }
      end

      def has_variants?
        variants.any?
      end

      def to_variant
        main_variant
      end

      def all_variants
        variants.to_a.prepend main_variant
      end

      def variants_for_table
        variants.order(name: :asc).order('cache_web_price_pennies asc')
      end

      def teaser_image
        if images.any? && images.first.image.present?
          images.ordered.first.image.square
        else
          'c/placeholder_product_image.png'
        end
      end

      def main_image
        if has_main_image?
          images.ordered.first.image.square
        else
          'c/placeholder_product_image.png'
        end
      end

      def has_main_image?
        images.any? && images.first.image.present?
      end

      def display_thumbnail
        if C.display_thumbnail
          case C.display_thumbnail
          when :ebay
            ebay_channel.channel_images.ordered.first&.image&.image&.thumbnail || thumbnail
          when :amazon
            amazon_channel.channel_images.ordered.first&.image&.image&.thumbnail || thumbnail
          else
            thumbnail
          end
        else
          thumbnail
        end
      end

      def thumbnail
        main_variant.cache_image&.image&.thumbnail
      end

      def categorise(category)
        categorizations.create(category_id: category.id) unless in?(category)
      end

      def uncategorise(category)
        categorizations.find_by(category_id: category.id).destroy
      end

      def in?(category)
        categorizations.find_by(category_id: category.id)
      end

      def longtitle(title)
        title = title.split
        if title.length > 7
          title.length.times do |i|
            title.slice!(7) if i > 7
          end
        end
        title.slice!(title.length - 1)
        shortened_title = ''
        title.map do |word|
          shortened_title += "#{word} "
        end
        shortened_title
      end

      def upload_to_amazon
        if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
          C::AmazonPipeline.push(variants)
        else
          C::AmazonJob.perform_now(:submit_products, variants.where(published_amazon: true))
        end
      end

      def table_color
        return '#d6d6d6' if main_variant.discontinued
        '#ffdddd' if main_variant.inactive?
      end

      def state
        if main_variant.discontinued
          'Discontinued'
        else
          main_variant.status.titleize
        end
      end

      def web_images
        web_channel.channel_images
      end

      def tax_rate_multiplier
        1 + (tax_rate / 100)
      end

      def last_amazon_push
        amazon_processing_queues
          .product
          .where.not(job_status: :processing)
          .order(completed_at: :desc)
          .first
      end

      def cache_amazon_results(status, message = nil)
        amazon_channel.update!(last_push_success: status, last_push_body: message)
      end

      # This is displaying the name in the masters table
      # Placed here to make the index table slightly less of a chore
      def table_name
        "<b>#{main_variant.sku}</b><br>#{(main_variant.name || '')[0..80]}"
      end

      def table_categories
        categories.order(name: :asc).pluck(:name).join(', ')
      end

      def get_google_category_id
        g_cats = categories.where.not(google_category_id: nil)
        return nil if g_cats.empty?
        g_cats.first.google_category.category_id
      end

      def merge_with(others)
        [others].flatten.each do |other|
          other.variants.each { |obj| obj.update(master_id: id, main_variant: false) }
          other.images.each { |obj| obj.update(master_id: id) }
          other.reload
          other.destroy!
        end
      end

      INDEX_TABLE = {
        'ROW_CLASS': { toggle: [{ condition: 'main_variant.discontinued', true: 'discontinued', false: '', nil: 'nil_data' },{ condition: 'main_variant.in_stock?', true: '', false: 'out_of_stock', nil: '' }, { condition: 'main_variant.display_only', true: 'display_only', false: '', nil: '' }] },
        '': { image: 'display_thumbnail' },
        'Product': { link: { name: { call: 'table_name' }, options: '[:ebay_auto_sync, object]' }, sort: 'main_variant_name' },
        'MPN': { call: 'main_variant.mpn', sort: 'main_variant_mpn' },
        'Brand': { link: { name: { call: 'brand&.name' }, options: '[object.brand]' }, sort: 'brand_name', filter: { label: "Brand", name: 'brand_name_eq', collection: 'C::Brand.all.order(name: :asc)', display: 'name' } },
        'Manufacturer': { link: { name: { call: 'manufacturer&.name' }, options: '[object.manufacturer]' }, sort: 'manufacturer_name', filter: { label: "Manufacturer", name: 'manufacturer_name_eq', collection: 'C::Brand.all.order(name: :asc)', display: 'name' } },
        'Categories': { call: 'table_categories', filter: { label: "Category", name: 'categories_name_eq', collection: 'C::Category.all.order(name: :asc)', display: 'name' } },
        'Web (£)': { price: { call: 'main_variant.cache_web_price' },
                     sort: 'main_variant_cache_web_price_pennies',
                     class: { toggle: { condition: 'main_variant.published_web', true: 'price-field success_data', false: 'price-field error_data', nil: 'price-field nil_data' } } },
        'Ebay (£)': { price: { call: 'main_variant.cache_ebay_price' },
                      sort: 'main_variant_cache_ebay_price_pennies',
                      class: { toggle: { condition: 'main_variant.ebay_last_push_success', true: 'price-field success_data', false: 'price-field error_data', nil: 'price-field nil_data' } },
                      display: 'C.master_tabs.keys.include?(:ebay)'},
        'Amazon (£)': {
          price: { call: 'main_variant.cache_amazon_price' },
          sort: 'main_variant_cache_amazon_price_pennies',
          class: { toggle: { condition: 'main_variant.amazon_last_push_success', true: 'price-field error_data', false: 'price-field success_data', nil: 'price-field nil_data' } },
          display: 'C.master_tabs.keys.include?(:amazon)'
        },
        'Stock': { call: 'main_variant.current_stock', sort: 'main_variant_current_stock' },
        '_Featured': { icon: 'star', condition: '!featured' }
      }.freeze

      REDUCED_INDEX = {
        'ROW_CLASS': { toggle: [{ condition: '!main_variant.discontinued', true: '', false: 'discontinued', nil: 'nil_data' },{ condition: '!main_variant.in_stock?', true: 'out_of_stock', false: '', nil: '' }] },
        '': { image: 'display_thumbnail' },
        'Product': { link: { name: { call: 'table_name' }, options: '[:ebay_auto_sync, object]' }, sort: 'main_variant_name' },
        'MPN': { call: 'main_variant.mpn', sort: 'main_variant_mpn' },
        'Brand': { link: { name: { call: 'brand&.name' }, options: '[object.brand]' }, sort: 'brand_name', filter: { name: 'brand_name_eq', collection: 'C::Brand.all', display: 'name' } },
        'Manufacturer': { link: { name: { call: 'manufacturer&.name' }, options: '[object.manufacturer]' }, sort: 'manufacturer_name', filter: { name: 'manufacturer_name_eq', collection: 'C::Brand.all', display: 'name' } },
        'Stock': { call: 'main_variant.current_stock', sort: 'main_variant_current_stock' },
        '_Featured': { icon: 'star', condition: '!featured' }
      }.freeze

      REDUCED_REDUCED_INDEX = {
        'Product': { link: { name: { call: 'table_name' }, options: '[:ebay_auto_sync, object]' }, sort: 'main_variant_name' },
        'MPN': { call: 'main_variant.mpn', sort: 'main_variant_mpn' },
        'Stock': { call: 'main_variant.current_stock', sort: 'main_variant_current_stock' },
      }.freeze

      BULK_ACTIONS = [
        ['-- Select --', ''],
        ['Add to Category', :category],
        ['Add to Collection', :collection],
        ['Add Shipping Cost', :shipping],
        ['Assign Brand', :brand],
        ['Assign Manufacturer', :manufacturer],
        ['Assign Property Value', :property_value],
        C.bulk_action_delete ? ['Delete Product', :delete] : nil,
        ['Discontinue Product', :discontinue],
        ['Download as CSV', :download_as_csv],
        ['Edit Country of Manufacture', :country],
        ['Merge Products', :merge_masters],
        ['Push to eBay', :push_to_ebay],
        ['Push to Amazon', :push_to_amazon],
        ['Push to Google', :push_to_google],
        ['Set to active', :active],
        ['Set to inactive', :make_inactive],
        ['Set Product Voucher', :product_voucher],
      ].compact.freeze

      def build_main_fields
        build_main_variant
        build_nested_elements
      end

      def build_nested_elements
        retail_price || main_variant.build_retail_price
        web_price || main_variant.build_web_price
        ebay_price || main_variant.build_ebay_price
        amazon_price || main_variant.build_amazon_price
        main_variant.barcodes.build if main_variant.barcodes.empty?
        main_variant.price_matches.build if main_variant.price_matches.empty?
        main_variant.bundle_items.build if main_variant.bundle_items.empty?

        ebay_channel.ship_to_locations.build if ebay_channel && ebay_channel.ship_to_locations.empty?
      end

      def amazon_validations
        if main_variant&.published_amazon && !amazon_channel.complete_and_valid?
          errors.add(:amazon_channel,
                     "has the following errors:
                     #{amazon_channel.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
