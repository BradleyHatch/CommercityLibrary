module C
  class WishlistItem < ApplicationRecord

    belongs_to :customer, class_name: 'C::Customer', foreign_key: 'customer_id'
    belongs_to :variant, class_name: 'C::Product::Variant', foreign_key: 'variant_id'

    validates :customer_id, presence: true
    validates :variant_id, presence: true

  end
end
