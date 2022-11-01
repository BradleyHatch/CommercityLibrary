class AddNoShippingServiceBoolToEbay < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :no_shipping_options, :boolean, default: false
  end
end
