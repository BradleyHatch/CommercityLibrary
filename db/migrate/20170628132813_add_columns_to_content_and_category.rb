class AddColumnsToContentAndCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :c_contents, :template_group_id, :integer
    add_column :c_categories, :template_group_id, :integer
  end
end
