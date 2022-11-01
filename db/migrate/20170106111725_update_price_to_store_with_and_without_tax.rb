# frozen_string_literal: true
class UpdatePriceToStoreWithAndWithoutTax < ActiveRecord::Migration[5.0]
  def change
    change_table :c_prices do |t|
      t.remove_monetize :cost_price
      t.remove_monetize :rrp
      t.remove_monetize :price

      t.monetize :with_tax
      t.decimal  :tax_rate, default: '20.0'
    end
  end
end
