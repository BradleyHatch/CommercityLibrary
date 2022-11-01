# frozen_string_literal: true
class AddBodyToOrderSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :body, :json
  end
end
