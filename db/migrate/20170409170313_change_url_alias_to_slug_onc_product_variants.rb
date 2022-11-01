class ChangeUrlAliasToSlugOncProductVariants < ActiveRecord::Migration[5.0]
  def change
    rename_column :c_product_variants, :url_alias, :slug
    rename_column :c_categories, :url_alias, :slug
    rename_column :c_brands, :url_alias, :slug
  end
end
