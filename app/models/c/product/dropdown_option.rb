module C
  class Product::DropdownOption < ApplicationRecord

    belongs_to :dropdown
    
    validates :name, presence: true
    validates :value, presence: true
  end
end
