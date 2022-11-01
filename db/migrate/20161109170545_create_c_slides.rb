# frozen_string_literal: true
class CreateCSlides < ActiveRecord::Migration[5.0]
  def change
    create_table :c_slides do |t|
      t.string :name
      t.text :body
      t.string :url
      t.string :image

      t.references :slideshow

      t.timestamps
    end
  end
end
