# frozen_string_literal: true
class AddEbayOrderIdColumnToCOrderSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :ebay_order_id, :string
  end
end
