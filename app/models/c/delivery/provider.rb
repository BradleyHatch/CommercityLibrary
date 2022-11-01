# frozen_string_literal: true

module C
  module Delivery
    class Provider < ApplicationRecord
      has_many :services, class_name: 'Delivery::Service', dependent: :destroy

      validates :name, presence: true

      INDEX_TABLE = {
        'Name': { primary: 'name' }
      }.freeze
    end
  end
end
