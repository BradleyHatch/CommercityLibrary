class AddBuildFromEbayFlagToVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :build_from_ebay, :boolean, default: false
  end
end
