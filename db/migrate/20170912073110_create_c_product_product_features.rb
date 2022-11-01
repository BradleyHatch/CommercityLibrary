class CreateCProductProductFeatures < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_product_features do |t|
      t.references :variant
      t.references :feature

      t.timestamps
    end
  end
end
