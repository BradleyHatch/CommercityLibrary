class AddTaxRateToCDeliveryServices < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_services, :tax_rate, :decimal, null: false, default: 20.0
  end
end
