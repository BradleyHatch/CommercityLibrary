class CreateCGoogleCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_google_categories do |t|
      t.string :name
      t.text :full_path

      t.string :category_id
      t.string :category_parent_name
      t.integer :parent_id

      t.timestamps
    end
  end
end
