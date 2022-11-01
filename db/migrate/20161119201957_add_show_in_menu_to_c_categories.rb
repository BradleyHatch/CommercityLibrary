# frozen_string_literal: true
class AddShowInMenuToCCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :in_menu, :boolean, default: false
  end
end
