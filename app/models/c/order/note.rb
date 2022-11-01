# frozen_string_literal: true

module C
  module Order
    class Note < ApplicationRecord
      belongs_to :created_by, class_name: 'C::User'
      belongs_to :order, class_name: 'C::Order::Sale'

      validates :created_by, presence: true
      validates :note, presence: true
      validates :order, presence: true
    end
  end
end
