# frozen_string_literal: true
class CreateCCategoryHierarchies < ActiveRecord::Migration[5.0]
  def change
    create_table :c_category_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end

    add_index :c_category_hierarchies, [:ancestor_id, :descendant_id, :generations],
              unique: true,
              name: 'category_anc_desc_idx'

    add_index :c_category_hierarchies, [:descendant_id],
              name: 'category_desc_idx'
  end
end
