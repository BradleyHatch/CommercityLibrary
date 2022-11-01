class AddReplaceImagesBoolToDatatransfer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_data_transfers, :replace_images, :boolean, default: false, null: false
  end
end
