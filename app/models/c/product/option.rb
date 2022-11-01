# frozen_string_literal: true

module C
  class Product::Option < ApplicationRecord
    include Priceable

    has_many :cart_item_option_variants, through: :option_variants, class_name: 'C::CartItemOptionVariant'
    has_many :variants, through: :option_variants, class_name: 'C::Product::Variant'
    has_many :option_variants, class_name: 'C::Product::OptionVariant', dependent: :destroy

    validates :price, presence: true
    validates :name, presence: true

    has_price

    def name_and_price
      "#{name} (#{ActionController::Base.helpers.humanized_money_with_symbol(price.with_tax)})"
    end
  end
end
