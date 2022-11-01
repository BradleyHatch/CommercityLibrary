# frozen_string_literal: true
class AddPrintedToCOrderSales < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :printed, :boolean, default: false
  end
end
