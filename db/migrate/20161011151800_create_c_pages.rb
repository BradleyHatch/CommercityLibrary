# frozen_string_literal: true
class CreateCPages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_pages do |t|
      t.string   :name
      t.text     :body
      t.string   :layout
      t.boolean  :in_menu
      t.string   :menu_item

      t.timestamps
    end
  end
end
