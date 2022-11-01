class CreateCProductDropdownCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_dropdown_categories do |t|

      t.belongs_to :dropdown
      t.belongs_to :category

      t.timestamps
    end
  end
end
