class AddVoucherIdToCCartItem < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_cart_items, :voucher, foreign_key: { to_table: :c_product_vouchers }
  end
end
