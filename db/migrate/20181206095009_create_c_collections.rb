class CreateCCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :c_collections do |t|
      t.string :name
      t.string :image
      t.string :slug
      t.text :body

      t.timestamps
    end
  end
end
