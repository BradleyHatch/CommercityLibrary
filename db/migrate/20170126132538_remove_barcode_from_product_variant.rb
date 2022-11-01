# frozen_string_literal: true
class RemoveBarcodeFromProductVariant < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_product_variants, :barcode_value, :string
    remove_column :c_product_variants, :barcode_type, :integer
  end
end
