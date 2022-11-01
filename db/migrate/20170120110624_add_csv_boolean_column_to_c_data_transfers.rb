# frozen_string_literal: true
class AddCsvBooleanColumnToCDataTransfers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_data_transfers, :csv, :boolean, default: false
  end
end
