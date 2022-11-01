
# frozen_string_literal: true

module C
  class Brand < ApplicationRecord
    include Pageinfoable
    include Sluggable

    has_many :products, class_name: 'C::Product::Master', dependent: :nullify
    has_many :manufactured_products, class_name: 'C::Product::Master', foreign_key: :manufacturer_id, dependent: :nullify

    has_many :brand_vouchers, dependent: :destroy, class_name: "C::Product::BrandVoucher"
    has_many :vouchers, through: :brand_vouchers, class_name: "C::Product::Voucher"

    has_many :categories, through: :products

    mount_uploader :image, BrandImageUploader

    validates :name, presence: true, uniqueness: true

    scope :featured, -> { where(featured: true) }
    scope :ordered, -> { order name: :asc }
    scope :active, -> {
      master_ids = C::Brand.joins(:products).select("c_product_masters.id")
      brand_ids = C::Product::Master.where(id: master_ids ).group(:id).joins(:variants).where(c_product_variants: { status: 0, published_web: true, discontinued: false }).select("c_product_masters.brand_id")
      where(id: brand_ids)
    }
    scope :in_menu, -> {
      where(in_menu: true)
    }

    INDEX_TABLE = {
      '_thumbnail': {
        image: 'image.thumb'
      },
      'Brand': {
        link: {
          name: {
            call: 'name'
          },
          options: '[:edit, object]'
        },
        sort: 'name'
      },
      'Product': {
        call: 'products.count'
      },
      'Edit': {
        link: {
          name: {
            text: 'edit'
          },
          options: '[:edit, object]'
        }
      }
    }.freeze

    BULK_ACTIONS = [
      ['Delete', :destroy]
    ].freeze

    # Standardise the way that variants are called
    def variants
      master_ids = C::Product::Master.where(brand_id: id).ids
      C::Product::Variant.where(master_id: master_ids)
    end

  end
end
