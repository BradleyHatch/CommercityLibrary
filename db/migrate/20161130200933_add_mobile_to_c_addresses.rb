# frozen_string_literal: true
class AddMobileToCAddresses < ActiveRecord::Migration[5.0]
  def change
    add_column :c_addresses, :mobile, :string
  end
end
