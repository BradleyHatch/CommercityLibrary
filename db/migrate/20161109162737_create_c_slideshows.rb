# frozen_string_literal: true
class CreateCSlideshows < ActiveRecord::Migration[5.0]
  def change
    create_table :c_slideshows do |t|
      t.string :name
      t.string :machine_name

      t.timestamps
    end
  end
end
