# frozen_string_literal: true
class CreateCCarts < ActiveRecord::Migration[5.0]
  def change
    create_table :c_carts do |t|
      t.references :customer, index: true
      t.references :shipping_address, index: true
      t.references :billing_address, index: true
      t.references :delivery, index: true
      t.references :payment, index: true

      t.references :order, index: true

      t.boolean :anonymous, default: false

      t.timestamps
    end
    add_foreign_key :c_carts, :c_customers, column: :customer_id
  end
end
