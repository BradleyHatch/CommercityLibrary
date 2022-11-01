# frozen_string_literal: true
class CreateCRoles < ActiveRecord::Migration[5.0]
  def change
    create_table :c_roles do |t|
      t.string :name
      t.text   :body

      t.timestamps
    end
  end
end
