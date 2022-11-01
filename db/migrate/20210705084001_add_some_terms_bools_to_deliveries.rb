class AddSomeTermsBoolsToDeliveries < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_deliveries, :terms_carriage_charges, :boolean, default: false, null: false
    add_column :c_order_deliveries, :terms_additional_charges, :boolean, default: false, null: false
  end
end
