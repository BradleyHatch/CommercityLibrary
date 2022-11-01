class CreateCProductDropdownOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_dropdown_options do |t|

      t.string :name
      t.string :value
      t.belongs_to :dropdown

      t.timestamps
    end
  end
end
