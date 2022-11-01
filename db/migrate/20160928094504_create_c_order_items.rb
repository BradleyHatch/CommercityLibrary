# frozen_string_literal: true
class CreateCOrderItems < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_items do |t|
      t.references :order, index: true
      t.references :product, index: true
      t.string :name
      t.monetize :price
      t.integer :quantity, default: 0

      t.timestamps
    end
  end
end
