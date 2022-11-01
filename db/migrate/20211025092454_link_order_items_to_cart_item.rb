class LinkOrderItemsToCartItem < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_order_items, :cart_item
  end
end
