class AddVoucherIdToSale < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :voucher_id, :integer, index: true
  end
end
