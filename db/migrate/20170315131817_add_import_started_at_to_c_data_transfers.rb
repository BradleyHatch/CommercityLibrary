# frozen_string_literal: true
class AddImportStartedAtToCDataTransfers < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_data_transfers, :imported_at, :import_finished_at
    add_column :c_data_transfers, :import_started_at, :datetime
  end
end
