class CreateCCartItemNotes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_cart_item_notes do |t|

      t.belongs_to :cart_item
      t.string :name
      t.string :value

      t.timestamps
    end
  end
end
