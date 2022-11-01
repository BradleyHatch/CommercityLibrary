# frozen_string_literal: true
class CreateCProductChannelWebs < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_webs do |t|
      t.references :master

      t.string :name
      t.text :description
      t.text :features
      t.text :specification

      t.monetize :current_price,  amount: { null: true, default: nil }
      t.monetize :discount_price, amount: { null: true, default: nil }

      t.timestamps
    end
    add_foreign_key :c_product_channel_webs, :c_product_masters, column: :master_id, on_delete: :restrict
  end
end
