class RemoveEbayFreeShippingColumn < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_product_channel_ebays, :free_shipping
  end
end
