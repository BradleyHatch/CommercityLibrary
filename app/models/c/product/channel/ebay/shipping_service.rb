# frozen_string_literal: true

module C
  class Product::Channel::Ebay::ShippingService < ApplicationRecord
    belongs_to :ebay, class_name: 'C::Product::Channel::Ebay'
    belongs_to :delivery_service, class_name: 'C::Delivery::Service'

    validates :ebay_id, presence: true
    validates :delivery_service_id, presence: true

    monetize :cost_pennies
    monetize :additional_cost_pennies

    # fallbacks to C.rb values if store values is blank
    # pass in 'ebay_shipping_international' to below method to return the
    # default international shipping service
    def default_service(service='ebay_shipping_service')
      if delivery_service_id.nil?
        C::Delivery::Service.find_by(name: C.send(service))&.id
      else
        delivery_service_id
      end
    end

    def default_cost
      if cost.blank? || cost.zero?
        C.ebay_shipping_cost
      else
        cost
      end
    end

    def default_additional_cost
      if additional_cost.blank? || additional_cost.zero?
        C.ebay_shipping_additional_cost
      else
        additional_cost
      end
    end
  end
end
