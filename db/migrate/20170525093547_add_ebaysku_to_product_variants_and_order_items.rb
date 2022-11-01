class AddEbayskuToProductVariantsAndOrderItems < ActiveRecord::Migration[5.0]
  def change

    add_column :c_product_variants, :ebay_sku, :string
    add_column :c_order_items, :ebay_sku, :string

  end
end
