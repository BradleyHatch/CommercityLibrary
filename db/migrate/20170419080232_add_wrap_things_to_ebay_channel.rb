class AddWrapThingsToEbayChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :shop_wrap, :text
  end
end
