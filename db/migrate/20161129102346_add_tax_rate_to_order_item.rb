# frozen_string_literal: true
class AddTaxRateToOrderItem < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_items, :tax_rate, :decimal
  end
end
