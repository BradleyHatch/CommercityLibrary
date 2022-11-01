module C
  class Delivery::ServiceVariant < ApplicationRecord 
    belongs_to :service, class_name: 'C::Delivery::Service'
    belongs_to :variant, class_name: 'C::Product::Variant'
  end
end
