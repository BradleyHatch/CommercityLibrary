# frozen_string_literal: true
class AddOverriddenToOrderDeliveries < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_deliveries, :overridden, :boolean, default: false
  end
end
