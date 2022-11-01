class AddPerItemDiscountMultiplierToProductVouchers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_vouchers, :per_item_discount_multiplier, :decimal, default: '1.0'
  end
end
