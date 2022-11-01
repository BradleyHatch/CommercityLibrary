# frozen_string_literal: true
class AddCustomerFieldsToCOrderSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :name, :string
    add_column :c_order_sales, :email, :string
    add_column :c_order_sales, :phone, :string
    add_column :c_order_sales, :mobile, :string
  end
end
