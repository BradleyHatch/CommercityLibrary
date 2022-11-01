class DoesNotApplyBarcodeBoolean < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_barcodes, :does_not_apply, :boolean, default: :false

  end
end
