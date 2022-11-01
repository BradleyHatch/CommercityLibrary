class CreateCProductFeatures < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_features do |t|
      t.string :name
      t.string :image
      t.text :body

      t.timestamps
    end
  end
end
