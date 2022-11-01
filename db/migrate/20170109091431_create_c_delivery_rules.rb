# frozen_string_literal: true
class CreateCDeliveryRules < ActiveRecord::Migration[5.0]
  def change
    create_table :c_delivery_rules do |t|
      t.references :service
      t.integer :zone_id
      t.decimal :base_price

      t.timestamps
    end
    add_monetize :c_delivery_rules, :max_cart_price, amount: { null: true, default: nil }
    add_monetize :c_delivery_rules, :min_cart_price, amount: { default: 0.0 }
  end
end
