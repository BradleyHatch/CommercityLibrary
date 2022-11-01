module C
  class CartItemNote < ApplicationRecord

    belongs_to :cart_item

    validates :name, presence: true
    validates :value, presence: true
  end
end
