class AddInfoToCOrderSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :info, :jsonb, default: {}, null: false
  end
end
