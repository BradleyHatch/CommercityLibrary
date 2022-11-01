# frozen_string_literal: true
class AddIndexOnSkuToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_index :c_product_variants, :sku, unique: true
  end
end
