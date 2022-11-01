# frozen_string_literal: true
class AddTaxRateToCProductMasters < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_masters, :tax_rate, :decimal, default: 20.0
  end
end
