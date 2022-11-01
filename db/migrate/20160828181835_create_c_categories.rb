# frozen_string_literal: true
class CreateCCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_categories do |t|
      t.string :name
      t.string :internal_id
      t.string :displayed_name
      t.text :body
      t.string :image
      t.references :parent
      t.integer :weight

      t.timestamps
    end
    add_foreign_key :c_categories, :c_categories, column: :parent_id, on_delete: :nullify
  end
end
