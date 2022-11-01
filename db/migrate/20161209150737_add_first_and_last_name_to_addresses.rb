# frozen_string_literal: true
class AddFirstAndLastNameToAddresses < ActiveRecord::Migration[5.0]
  def change
    add_column :c_addresses, :first_name, :string
    add_column :c_addresses, :last_name, :string
  end
end
