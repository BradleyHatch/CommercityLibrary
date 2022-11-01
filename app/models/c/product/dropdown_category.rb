module C
  class Product::DropdownCategory < ApplicationRecord
    belongs_to :category, class_name: 'C::Category'
    belongs_to :dropdown, class_name: 'C::Product::Dropdown'
  end
end
