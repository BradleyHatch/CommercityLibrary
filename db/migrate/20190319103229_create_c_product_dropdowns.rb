class CreateCProductDropdowns < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_dropdowns do |t|

      t.string :name
      t.boolean :active

      t.timestamps
    end
  end
end
