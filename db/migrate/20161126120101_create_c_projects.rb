# frozen_string_literal: true
class CreateCProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :c_projects do |t|
      t.string :name
      t.text :body
      t.string :url_alias

      t.timestamps
    end
  end
end
