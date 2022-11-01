# frozen_string_literal: true
class RemovePositionFromCProductBarcodes < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_product_barcodes, :position, :integer
  end
end
