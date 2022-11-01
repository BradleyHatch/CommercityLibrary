class AddMoneyOrderPaymentMethod < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :payment_method_money_order, :boolean, default: false
  end
end
