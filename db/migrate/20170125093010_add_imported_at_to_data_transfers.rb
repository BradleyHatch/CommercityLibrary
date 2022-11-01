# frozen_string_literal: true
class AddImportedAtToDataTransfers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_data_transfers, :imported_at, :datetime
  end
end
