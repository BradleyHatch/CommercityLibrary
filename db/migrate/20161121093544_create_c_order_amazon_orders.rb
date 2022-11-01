# frozen_string_literal: true
class CreateCOrderAmazonOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_amazon_orders do |t|
      t.string :amazon_id
      t.string :buyer_name
      t.string :buyer_email
      t.string :selected_shipping
      t.date :earliest_delivery_date
      t.date :latest_delivery_date
      t.text :body

      t.belongs_to :order

      t.timestamps
    end
  end
end
