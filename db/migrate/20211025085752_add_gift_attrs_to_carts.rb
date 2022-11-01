class AddGiftAttrsToCarts < ActiveRecord::Migration[5.0]
  def change
    add_column :c_cart_items, :gift_wrapping, :boolean, default: false, null: false
    add_column :c_order_items, :gift_wrapping, :boolean, default: false, null: false
  end
end
