class CopySkuToEbaySku < ActiveRecord::Migration[5.0]
  # fix for order_items getting destroyed from find_by ebay_sku

  def up
    C::Order::Item.all.map { |item| item.update(ebay_sku: item.sku) }
  end

  def down
  end

end
