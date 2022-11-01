# frozen_string_literal: true
class CreateCOrderEbayOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_ebay_orders do |t|
      t.string :ebay_order_id
      t.string :buyer_username
      t.string :buyer_email
      t.text :transaction_id
      t.string :gateway_transaction_id
      t.text :body

      t.belongs_to :order

      t.timestamps
    end
  end
end
