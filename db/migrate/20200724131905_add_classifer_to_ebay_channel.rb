class AddClassiferToEbayChannel < ActiveRecord::Migration[5.0]
  def change
     add_reference :c_product_channel_ebays, :classifier_property_key
  end
end
