class AddSageFieldsToCOrderSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :export_status, :integer
  end
end
