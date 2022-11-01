# frozen_string_literal: true

module C
  class Product::Wrap < ApplicationRecord
    validates :name, presence: true
    validates :wrap, presence: true

    def sub_description
      'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    end

    def sub_title
      'Lorem ipsum'
    end

    def sub_price
      '4.99'
    end

    def sub_image
      '/assets/c/placeholder_product_image.png'
    end

    def subbed_wrap
      tags = {
        '[{PRODUCT_DESCRIPTION}]': 'sub_description',
        '[{PRODUCT_LISTING_TITLE}]': 'sub_title',
        '[{PRODUCT_LISTING_PRICE}]': 'sub_price',
        '[{PRODUCT_IMAGE_1}]': 'sub_image',
        '[{PRODUCT_IMAGE_2}]': 'sub_image',
        '[{PRODUCT_IMAGE_3}]': 'sub_image',
        '[{PRODUCT_IMAGE_4}]': 'sub_image'
      }

      subbed_wrap = wrap

      tags.each do |tag, value|
        subbed_wrap = subbed_wrap.gsub(tag.to_s, send(value))
      end

      subbed_wrap
    end

    INDEX_TABLE = {
      'Name': { primary: 'name' }
    }.freeze
  end
end
