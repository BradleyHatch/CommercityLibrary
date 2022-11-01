# frozen_string_literal: true
class CreateCTeamMembers < ActiveRecord::Migration[5.0]
  def change
    create_table :c_team_members do |t|
      t.string :name
      t.string :role
      t.string :image
      t.text :body

      t.timestamps
    end
  end
end
