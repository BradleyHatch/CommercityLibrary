# frozen_string_literal: true
class CreateCMenuItems < ActiveRecord::Migration[5.0]
  def change
    create_table :c_menu_items do |t|
      t.string :name
      t.string :link
      t.boolean :visible, default: true

      t.integer :parent_id
      t.integer :weight

      t.string :machine_name

      t.belongs_to :page, index: true, allow_nil: true

      t.timestamps
    end
    add_foreign_key :c_menu_items, :c_menu_items, column: :parent_id, on_delete: :nullify
  end
end
