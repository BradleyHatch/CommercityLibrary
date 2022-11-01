class AddBundleToCProductVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :bundle, :boolean, default: false
  end
end
