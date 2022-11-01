class ChangeGoogleCategoryNameOnCCategoryModel < ActiveRecord::Migration[5.0]
  def change

    remove_column :c_categories, :google_category
    add_column :c_categories, :google_category_id, :integer

  end
end
