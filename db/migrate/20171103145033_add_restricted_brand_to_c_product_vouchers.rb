class AddRestrictedBrandToCProductVouchers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_vouchers, :restricted_brand, :boolean, default: false, null: false
  end
end
