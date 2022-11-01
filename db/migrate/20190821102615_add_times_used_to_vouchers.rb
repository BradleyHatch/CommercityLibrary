class AddTimesUsedToVouchers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_vouchers, :times_used, :integer, default: 0
  end
end
