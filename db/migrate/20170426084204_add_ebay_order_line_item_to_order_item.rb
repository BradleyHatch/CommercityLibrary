class AddEbayOrderLineItemToOrderItem < ActiveRecord::Migration[5.0]
  def change
    add_column :c_order_items, :ebay_order_line_item_id, :string
  end
end
