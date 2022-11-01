# frozen_string_literal: true
class AddMaxAndMinPricesToDeliveryServicePrices < ActiveRecord::Migration[5.0]
  def change
    add_monetize :c_delivery_service_prices, :max_cart_price, amount: { null: true, default: nil }
    add_monetize :c_delivery_service_prices, :min_cart_price
  end
end
