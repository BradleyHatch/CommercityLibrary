class CreateCProductVariantVouchers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_variant_vouchers do |t|
      t.references :voucher, foreign_key: { to_table: :c_product_vouchers }
      t.references :variant, foreign_key: { to_table: :c_product_variants }

      t.timestamps
    end
  end
end
