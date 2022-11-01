class AddDispatchDateToSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :dispatched_at, :datetime
  end
end
