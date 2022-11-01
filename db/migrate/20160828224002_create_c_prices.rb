# frozen_string_literal: true
class CreateCPrices < ActiveRecord::Migration[5.0]
  def change
    create_table :c_prices do |t|
      t.monetize :cost_price
      t.monetize :rrp
      t.monetize :without_tax
      t.monetize :price

      t.timestamps
    end
  end
end
