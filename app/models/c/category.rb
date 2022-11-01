# frozen_string_literal: true

module C
  class Category < ApplicationRecord
    include Pageinfoable
    include Sluggable
    include TemplatePageable

    acts_as_tree order: 'weight'

    scope :featured, -> { where(featured: true) }

    has_many :categorizations, class_name: 'C::Product::Categorization'
    has_many :products, through: :categorizations
    has_many :variants, through: :products, class_name: 'C::Product::Variant'
    has_many :brands, through: :products, class_name: 'C::Brand'
    has_many :property_values, through: :variants,
                               class_name: 'C::Product::PropertyValue'

    has_many :category_property_keys
    has_many :property_keys, through: :category_property_keys,
                             class_name: 'C::Product::PropertyKey'

    belongs_to :amazon_product_type
    belongs_to :ebay_category, class_name: 'C::EbayCategory'
    belongs_to :google_category, class_name: 'C::GoogleCategory'

    scope :alphabetical, -> { order(name: :asc) }

    # validations
    validates :name, presence: true

    mount_uploader :image, CategoryImageUploader
    mount_uploader :image_alt, CategoryImageUploader

    def self_and_descendant_products
      C::Product::Master.joins(:categorizations)
                        .where(c_product_categorizations: {
                                 category_id: self_and_descendants
                               })
    end
  
    def self_and_descendant_product_variants
      C::Product::Variant.where(master_id: self_and_descendant_products)
    end

    def self_and_descendant_brands
      C::Brand.where(
        id: self_and_descendant_products.map(&:brand_id).uniq.compact
      )
    end

    def self_and_descendant_property_keys
      C::Product::PropertyKey
        .includes(:category_property_keys)
        .where(
          c_category_property_keys: { category_id: self_and_descendant_ids }
        )
    end

    def category_image_with_default
      if image.blank?
        products.first&.main_variant&.primary_web_image || 'placeholder.png'
      else
        image
      end
    end

    def name_with_parent
      parent ? "#{name} (#{parent.name})" : name
    end
  end
end
