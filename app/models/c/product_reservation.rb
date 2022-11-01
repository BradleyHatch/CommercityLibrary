# frozen_string_literal: true

module C
  class ProductReservation < ApplicationRecord
    scope :ordered, -> { order created_at: :desc }
    scope :with_valid_product, lambda {
      includes(:product_variant).where.not(c_product_variants: { id: nil })
    }

    belongs_to :product_variant, class_name: C::Product::Variant

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    
    validates :name, :phone, :product_variant, presence: true

    validates :email,
              presence: true,
              length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX }

    after_create do
      if (reference.blank?)
        string = Base64.encode64("#{id}#{created_at}").upcase
        string = string.length > 5 ? "#{string[0...5]}" : string
        update(reference: "#{string}BHJ")
      end
    end
    
    INDEX_TABLE = {
      'Name': {
        call: 'name',
        sort: 'name'
      },
      'Email': {
        call: 'email',
        sort: 'email'
      },
      'Phone': {
        call: 'phone',
        sort: 'phone'
      },
      'Reference': {
        call: 'reference',
        sort: 'reference'
      },
      'Product': {
        link: {
          name: {
            call: 'product_variant.name'
          },
          options: '[:edit, product_variant.master]'
        },
        sort: 'product_variant_name'
      },
      'Date': {
        call: 'created_at',
        sort: 'created_at'
      }
    }.freeze
  end
end
