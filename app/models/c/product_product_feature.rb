module C
  class ProductProductFeature < ApplicationRecord
    belongs_to :product, class_name: 'C::Product::Variant'
    belongs_to :feature, class_name: 'C::Product::Feature'
  end
end
