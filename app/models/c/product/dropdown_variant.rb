module C
  class Product::DropdownVariant < ApplicationRecord
    belongs_to :variant
    belongs_to :dropdown
  end
end
