# frozen_string_literal: true
class CreateCCartItems < ActiveRecord::Migration[5.0]
  def change
    create_table :c_cart_items do |t|
      t.integer :quantity, default: 0

      t.references :variant
      t.references :cart

      t.timestamps
    end
  end
end
