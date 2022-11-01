# frozen_string_literal: true
class CreateCAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :c_addresses do |t|
      t.references :customer
      t.string :name
      t.string :address_one
      t.string :address_two
      t.string :address_three
      t.string :city
      t.string :region
      t.string :postcode
      t.references :country
      t.string :phone
      t.string :fax
      t.boolean :default, default: false

      t.timestamps
    end
  end
end
