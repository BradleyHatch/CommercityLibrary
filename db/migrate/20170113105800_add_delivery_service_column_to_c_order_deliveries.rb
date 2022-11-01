# frozen_string_literal: true
class AddDeliveryServiceColumnToCOrderDeliveries < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_deliveries, :delivery_service_id, :integer
  end
end
