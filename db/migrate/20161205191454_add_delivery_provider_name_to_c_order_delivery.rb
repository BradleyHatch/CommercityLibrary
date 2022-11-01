# frozen_string_literal: true
class AddDeliveryProviderNameToCOrderDelivery < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_deliveries, :delivery_provider, :string
  end
end
