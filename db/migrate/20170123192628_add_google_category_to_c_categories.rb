# frozen_string_literal: true
class AddGoogleCategoryToCCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :google_category, :string
  end
end
