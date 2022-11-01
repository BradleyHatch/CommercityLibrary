# frozen_string_literal: true
class CreateCDataTransfers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_data_transfers do |t|
      t.string :name
      t.string :file

      t.timestamps
    end
  end
end
