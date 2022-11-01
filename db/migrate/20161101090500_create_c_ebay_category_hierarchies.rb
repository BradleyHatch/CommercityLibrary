# frozen_string_literal: true
class CreateCEbayCategoryHierarchies < ActiveRecord::Migration[5.0]
  def change
    create_table :c_ebay_category_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end

    add_index :c_ebay_category_hierarchies, [:ancestor_id, :descendant_id, :generations],
              unique: true,
              name: 'ebay_category_anc_desc_idx'

    add_index :c_ebay_category_hierarchies, [:descendant_id],
              name: 'ebay_category_desc_idx'
  end
end
