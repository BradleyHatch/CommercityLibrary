class CreateCCollectionCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_collection_categories do |t|
      t.references :collection
      t.references :category

      t.timestamps
    end
  end
end
