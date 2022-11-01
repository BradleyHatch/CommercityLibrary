# frozen_string_literal: true
class CreateCOrderDeliveries < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_deliveries do |t|
      t.string :name
      t.monetize :price
      t.datetime :processing_at
      t.datetime :shipped_at
      t.string :tracking_code

      t.belongs_to :delivery_service_price, index: true

      t.timestamps
    end
  end
end
