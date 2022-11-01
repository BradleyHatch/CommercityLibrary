class DoesNotApplyBarcodeUpdate < ActiveRecord::Migration[5.0]
  def change

    remove_column :c_product_barcodes, :does_not_apply
    add_column :c_product_variants, :no_barcodes, :boolean, default: :false

  end
end
