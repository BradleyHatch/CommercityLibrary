# frozen_string_literal: true
class AddSalesHashFieldsToCOrderSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :channel_hash, :text
  end
end
