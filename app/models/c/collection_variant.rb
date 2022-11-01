module C
  class CollectionVariant < ApplicationRecord
    belongs_to :variant, class_name: 'C::Product::Variant'
    belongs_to :collection, class_name: 'C::Collection'
  end
end
