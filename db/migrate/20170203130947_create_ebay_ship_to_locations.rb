# frozen_string_literal: true
class CreateEbayShipToLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_ebay_ship_to_locations do |t|
      t.references :ebay
      t.integer :location

      t.timestamps
    end
  end
end
