class AddCategoryVoucherThings < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_category_vouchers do |t|
      t.references :category, foreign_key: { to_table: :c_categories }
      t.references :voucher, foreign_key: { to_table: :c_product_vouchers }

      t.timestamps
    end

    add_column :c_product_vouchers, :restricted_category, :boolean, default: false, null: false
  end
end
