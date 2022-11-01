class AddTaxRateToCOrderDeliveries < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_deliveries, :tax_rate, :decimal, null: false, default: 20.0
  end
end
