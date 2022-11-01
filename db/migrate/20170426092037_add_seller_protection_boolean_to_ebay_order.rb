class AddSellerProtectionBooleanToEbayOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_ebay_orders, :seller_protection, :boolean, default: false
  end
end
