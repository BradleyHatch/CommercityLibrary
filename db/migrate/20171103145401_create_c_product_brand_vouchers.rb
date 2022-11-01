class CreateCProductBrandVouchers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_brand_vouchers do |t|
      t.references :brand, foreign_key: { to_table: :c_brands }
      t.references :voucher, foreign_key: { to_table: :c_product_vouchers }

      t.timestamps
    end
  end
end
