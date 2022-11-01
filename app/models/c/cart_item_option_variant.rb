# frozen_string_literal: true

module C
  class CartItemOptionVariant < ApplicationRecord
    include Priceable

    belongs_to :cart_item, class_name: 'C::CartItem'
    belongs_to :option_variant, class_name: 'C::Product::OptionVariant'

    validates :cart_item, presence: true
    validates :option_variant, presence: true
    validates :price, presence: true

    has_price

    before_validation :set_price, on: :create

    def set_price
      self.price = option_variant.option.price.create_dup unless price
    end
  end
end
