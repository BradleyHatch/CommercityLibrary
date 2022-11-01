class RenameEbayBodyToDescription < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_product_channel_ebays, :body, :description
  end
end
