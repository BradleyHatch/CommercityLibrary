class CreateCProductDropdownVariants < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_dropdown_variants do |t|

      t.belongs_to :dropdown
      t.belongs_to :variant

      t.timestamps
    end
  end
end
