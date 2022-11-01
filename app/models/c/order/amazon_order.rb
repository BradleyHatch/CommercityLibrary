# frozen_string_literal: true

module C
  module Order
    class AmazonOrder < ApplicationRecord
      belongs_to :order, class_name: C::Order::Sale
      validates :amazon_id, presence: true, uniqueness: true
      validates :buyer_email, presence: true
    end
  end
end
