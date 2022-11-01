# frozen_string_literal: true
class CreateCCountries < ActiveRecord::Migration[5.0]
  def change
    create_table :c_countries do |t|
      t.string :name
      t.string :iso2
      t.string :iso3
      t.string :tld
      t.string :currency
      t.boolean :eu, default: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
