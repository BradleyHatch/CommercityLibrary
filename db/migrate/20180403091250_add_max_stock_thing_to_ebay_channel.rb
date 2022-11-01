class AddMaxStockThingToEbayChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :max_stock, :integer, default: 0
  end
end
