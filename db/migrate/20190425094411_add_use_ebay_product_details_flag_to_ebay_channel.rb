class AddUseEbayProductDetailsFlagToEbayChannel < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_channel_ebays, :uses_ebay_catalogue, :boolean, default: false
  end
end
