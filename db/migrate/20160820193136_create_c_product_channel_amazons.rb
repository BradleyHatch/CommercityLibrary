# frozen_string_literal: true
class CreateCProductChannelAmazons < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_amazons do |t|
      t.references :master

      t.string :name
      t.text :recommended_browse_nodes
      t.text :description
      t.text :features
      t.text :key_product_features
      t.text :condition_note

      t.monetize :current_price, default: 0
      t.monetize :de_price, default: 0
      t.monetize :es_price, default: 0
      t.monetize :fr_price, default: 0
      t.monetize :it_price, default: 0
      t.monetize :shipping_cost, default: 0

      t.timestamps
    end
    add_foreign_key :c_product_channel_amazons, :c_product_masters, column: :master_id, on_delete: :restrict
  end
end
