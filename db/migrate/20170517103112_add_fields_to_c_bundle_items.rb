class AddFieldsToCBundleItems < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_bundle_items, :price_pennies, :web_price_pennies
    rename_column :c_bundle_items, :price_currency, :web_price_currency
    add_monetize :c_bundle_items, :ebay_price
    add_monetize :c_bundle_items, :amazon_price
  end
end
