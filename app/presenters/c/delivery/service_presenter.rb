# frozen_string_literal: true

module C
  module Delivery
    class ServicePresenter < BasePresenter
      presents :delivery_service

      def for_select(*args)
        ds = delivery_service

        price = if  C.manual_delivery || C.combined_delivery_rate
                  for_combined_select(*args)
                elsif C.flat_delivery_rate
                  for_cart_select(*args)
                else
                  for_weight_select(*args)
                end

        ["#{ds.service_name} (#{price})", ds.id]
      rescue C::Delivery::Service::NoPriceFound
        nil
      end

      def for_combined_select(cart_total, zone)
        format_price(
          delivery_service.price_for_cart_total_and_zone(cart_total, zone)
        )
      end

      def for_weight_select(weight, zone)
        format_price delivery_service.price(weight, zone)
      end

      def for_cart_select(cart_total)
        format_price delivery_service.price_for_cart_total(cart_total)
      end

      def format_price(price)
        display_price = C.default_tax == :with_tax ? price.with_tax : price.with_tax / price.tax_multiplier
        if price.zero?
          'Free'
        else
          humanized_money_with_symbol display_price
        end
      end
    end
  end
end
