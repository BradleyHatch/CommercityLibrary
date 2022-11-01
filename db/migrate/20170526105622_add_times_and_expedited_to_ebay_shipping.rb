class AddTimesAndExpeditedToEbayShipping < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_channel_ebay_shipping_services, :ship_time_max, :integer
    add_column :c_product_channel_ebay_shipping_services, :ship_time_min, :integer
    add_column :c_product_channel_ebay_shipping_services, :expedited, :boolean, default: false

  end
end
