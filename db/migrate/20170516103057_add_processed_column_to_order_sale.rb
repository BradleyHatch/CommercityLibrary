class AddProcessedColumnToOrderSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :processed, :boolean, default: false
  end
end
