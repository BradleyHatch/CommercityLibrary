# frozen_string_literal: true

module C
  class Product::Channel::Ebay::ShipToLocation < ApplicationRecord
    include EbayLocation

    belongs_to :ebay, class_name: 'C::Product::Channel::Ebay'

    validates :location, presence: true

    def default_location
      location.nil? ? C.ebay_ship_to_location : location
    end

  end
end
