class RemoveIndexFromBarcode < ActiveRecord::Migration[5.0]
  def change
    remove_index :c_product_barcodes, [:value, :symbology]
  end
end
