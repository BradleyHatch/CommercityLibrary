# frozen_string_literal: true
class CreateCBrands < ActiveRecord::Migration[5.0]
  def change
    create_table :c_brands do |t|
      t.string :name
      t.text :body
      t.string :internal_id
      t.string :url
      t.string :image

      t.boolean :manufacturer
      t.boolean :supplier

      t.timestamps
    end
  end
end
