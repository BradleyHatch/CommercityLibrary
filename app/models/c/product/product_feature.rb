# frozen_string_literal: true

module C
  module Product
    class ProductFeature < ApplicationRecord
      include Orderable
      
      belongs_to :product, class_name: 'C::Product::Variant', foreign_key: 'variant_id'
      belongs_to :feature, class_name: 'C::Product::Feature'
    end
  end
end
