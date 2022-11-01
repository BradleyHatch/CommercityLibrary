# frozen_string_literal: true

module C
  class Product::OptionVariant < ApplicationRecord
    belongs_to :option, class_name: 'C::Product::Option'
    belongs_to :variant, class_name: 'C::Product::Variant'

    has_many :cart_item_option_variants, class_name: 'C::CartItemOptionVariant', dependent: :destroy

    validates :option, presence: true
    validates :variant, presence: true
  end
end
