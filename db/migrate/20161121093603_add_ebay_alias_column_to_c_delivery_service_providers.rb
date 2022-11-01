# frozen_string_literal: true
class AddEbayAliasColumnToCDeliveryServiceProviders < ActiveRecord::Migration[5.0]
  def change
    add_column :c_delivery_services, :ebay_alias, :string
    add_column :c_product_channel_ebays, :delivery_service_id, :integer
    remove_column :c_product_channel_ebays, :domestic_shipping_service
  end
end
