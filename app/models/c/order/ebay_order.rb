# frozen_string_literal: true

module C
  module Order
    class EbayOrder < ApplicationRecord
      belongs_to :order, class_name: C::Order::Sale
      validates :ebay_order_id, presence: true, uniqueness: true

      def seller_protection_eligibility
        seller_protection ? 'Eligible' : 'Not Eligible'
      end
    end
  end
end
