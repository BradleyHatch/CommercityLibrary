class AddOtherCacheFieldsToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_monetize :c_product_variants, :cache_ebay_price, amount: { default: 0.0 }
    add_monetize :c_product_variants, :cache_amazon_price, amount: { default: 0.0 }
    add_reference :c_product_variants, :cache_image, index: true
  end
end
