class RenameTheEbayChannelCategoryColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_product_channel_ebays, :category_id, :ebay_category_id
  end
end
