# frozen_string_literal: true
class AddOverrideToCPrices < ActiveRecord::Migration[5.0]
  def change
    add_column :c_prices, :override, :boolean, default: false
  end
end
