# frozen_string_literal: true
class CreateCOrderSales < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_sales do |t|
      t.references :customer, index: true
      t.references :shipping_address, index: true
      t.references :billing_address, index: true
      t.references :delivery, index: true
      t.references :payment, index: true

      # checkout - addresses, checkout-shipping, checkout-payment, received, processing, shipped
      t.integer :status, default: 0
      t.integer :channel, default: 0
      t.integer :flag, default: 0

      t.text :checkout_notes

      t.datetime :recieved_at

      t.timestamps
    end
  end
end
