class AddCheckoutMessageColumToEbayOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_ebay_orders, :checkout_message, :text
  end
end
