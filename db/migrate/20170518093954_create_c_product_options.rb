class CreateCProductOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_options do |t|
      t.string :name
      t.references :price, foreign_key: { to_table: :c_prices }

      t.timestamps
    end
  end
end
