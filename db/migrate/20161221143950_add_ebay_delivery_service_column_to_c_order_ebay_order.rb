# frozen_string_literal: true
class AddEbayDeliveryServiceColumnToCOrderEbayOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_ebay_orders, :ebay_delivery_service, :string
  end
end
