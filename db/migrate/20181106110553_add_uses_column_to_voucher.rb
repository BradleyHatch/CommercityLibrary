class AddUsesColumnToVoucher < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_vouchers, :uses, :integer, default: 0
  end
end
