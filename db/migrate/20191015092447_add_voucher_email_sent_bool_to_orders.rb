class AddVoucherEmailSentBoolToOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_sales, :voucher_email_sent, :boolean, default: false
  end
end
