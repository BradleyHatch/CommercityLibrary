# frozen_string_literal: true
class CreateCOrderNotes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_order_notes do |t|
      t.string :note
      t.references :order, index: true
      t.references :user

      t.timestamps
    end
  end
end
