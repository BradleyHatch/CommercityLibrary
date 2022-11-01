# frozen_string_literal: true
class FixInternationalColumnShippingName < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_product_channel_ebays, :international_shipping_service, :international_shipping_service_id
  end
end
