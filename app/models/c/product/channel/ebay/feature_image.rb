module C
  class Product::Channel::Ebay::FeatureImage < ApplicationRecord
    include Orderable
    
    belongs_to :ebay, class_name: 'C::Product::Channel::Ebay'
    belongs_to :image, class_name: 'C::Product::Image'
  end
end
