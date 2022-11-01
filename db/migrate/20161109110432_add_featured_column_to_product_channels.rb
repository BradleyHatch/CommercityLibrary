# frozen_string_literal: true
class AddFeaturedColumnToProductChannels < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :featured, :boolean, default: false
    add_column :c_brands, :featured, :boolean, default: false
    add_column :c_categories, :featured, :boolean, default: false
  end
end
