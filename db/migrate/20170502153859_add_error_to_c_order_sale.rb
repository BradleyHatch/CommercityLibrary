class AddErrorToCOrderSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :export_error_log, :text
  end
end
