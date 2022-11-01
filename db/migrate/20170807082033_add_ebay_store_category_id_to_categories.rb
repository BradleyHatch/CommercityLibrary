class AddEbayStoreCategoryIdToCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :ebay_store_category_id, :string
  end
end
