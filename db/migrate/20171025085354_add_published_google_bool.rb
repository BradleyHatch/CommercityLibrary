class AddPublishedGoogleBool < ActiveRecord::Migration[5.0]
  def change
    add_column :c_product_variants, :published_google, :boolean, default: false
  end
end
