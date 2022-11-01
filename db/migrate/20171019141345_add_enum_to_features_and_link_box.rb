class AddEnumToFeaturesAndLinkBox < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_features, :feature_type, :integer
    add_column :c_product_features, :link, :string
  end
end
