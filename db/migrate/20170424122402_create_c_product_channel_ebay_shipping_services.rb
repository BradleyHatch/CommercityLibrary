class CreateCProductChannelEbayShippingServices < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_ebay_shipping_services do |t|

      t.integer :ebay_id
      t.integer :delivery_service_id
      t.boolean :international, default: false
      t.monetize :cost
      t.monetize :additional_cost

      t.timestamps
    end
  end
end
