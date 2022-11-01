# frozen_string_literal: true
class MakePendingStatusDefaultOnOrderSale < ActiveRecord::Migration[5.0]
  def change
    change_column_default :c_order_sales, :status, from: 0, to: 5
  end
end
