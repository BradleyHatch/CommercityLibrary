# frozen_string_literal: true
class AddUrlAliasToCPages < ActiveRecord::Migration[5.0]
  def change
    add_column :c_pages, :url_alias, :string
    add_column :c_services, :url_alias, :string
    add_column :c_blogs, :url_alias, :string
    add_column :c_product_variants, :url_alias, :string
    add_column :c_categories, :url_alias, :string
    add_column :c_brands, :url_alias, :string
  end
end
