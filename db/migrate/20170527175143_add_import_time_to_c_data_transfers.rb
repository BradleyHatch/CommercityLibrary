class AddImportTimeToCDataTransfers < ActiveRecord::Migration[5.0]
  def change
    add_column :c_data_transfers, :import_at, :datetime
  end
end
