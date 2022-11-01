# frozen_string_literal: true
class AddEnumColumnToDataTransfer < ActiveRecord::Migration[5.0]
  def change
    remove_column :c_data_transfers, :csv, :boolean
    remove_column :c_data_transfers, :body, :json
    add_column :c_data_transfers, :import_type, :integer
  end
end
