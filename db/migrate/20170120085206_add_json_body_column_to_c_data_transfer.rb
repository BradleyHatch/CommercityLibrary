# frozen_string_literal: true
class AddJsonBodyColumnToCDataTransfer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_data_transfers, :body, :json
  end
end
