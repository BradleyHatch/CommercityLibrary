# frozen_string_literal: true

module C
  module Order
    class Delivery < ApplicationRecord
      before_save :copy_price_attrs

      belongs_to :courier, class_name: 'C::DeliveryServiceProvider'
      belongs_to :delivery_service, class_name: 'Delivery::Service'
      has_one :sale
      has_many :trackings, class_name: 'C::Order::Tracking', dependent: :destroy
      accepts_nested_attributes_for :trackings, allow_destroy: true, reject_if: ->(tracking) { tracking[:number].blank? && tracking[:provider].blank? }

      attr_accessor :calculated_price

      # set when initially building the sale
      attr_accessor :temp_sale

      monetize :price_pennies

      def valid_for_cart_amount?(cart_amount, zone)
        return true if overridden
        ds = delivery_service
        cart_is_above_minimum = (ds.min_cart_price(zone) < cart_amount)
        max_cart_price = ds.max_cart_price(zone)
        cart_is_below_maximum = (
        max_cart_price.nil? || (max_cart_price > cart_amount)
        )
        (cart_is_above_minimum && cart_is_below_maximum)
      end

      def tax
        tax_rate = (self.tax_rate || 0) / 100 || 0
        price * (tax_rate / (1 + tax_rate))
      end

      def price_without_tax
        price - tax
      end

      def tracking_code
        trackings.first.number if trackings.present?
      end

      def delivery_provider
        trackings.first.provider if trackings.present?
      end

      def click_and_collect?
        delivery_service && delivery_service.click_and_collect?
      end

      private

      def copy_price_attrs
        return if delivery_service.nil?
        unless overridden || @calculated_price.nil?
          self.price = @calculated_price
        end
        self.name = delivery_service.name
      end
    end
  end
end
