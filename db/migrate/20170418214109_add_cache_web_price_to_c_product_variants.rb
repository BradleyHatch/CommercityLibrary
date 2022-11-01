class AddCacheWebPriceToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_monetize :c_product_variants, :cache_web_price, amount: { default: 0.0 }
  end
end
