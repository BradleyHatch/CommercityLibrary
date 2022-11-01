# frozen_string_literal: true
class AddIndexOnValueAndSymbologyToCProductBarcodes < ActiveRecord::Migration[5.0]
  def change
    add_index :c_product_barcodes, [:value, :symbology], unique: true
  end
end
