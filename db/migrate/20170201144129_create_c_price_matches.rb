# frozen_string_literal: true
class CreateCPriceMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_price_matches do |t|
      t.integer :competitor
      t.references :variant
      t.string :url
      t.monetize :price

      t.timestamps
    end
  end
end
