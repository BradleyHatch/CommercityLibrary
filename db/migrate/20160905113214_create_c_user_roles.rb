# frozen_string_literal: true
class CreateCUserRoles < ActiveRecord::Migration[5.0]
  def change
    create_table :c_user_roles do |t|
      t.references :user
      t.references :role

      t.timestamps
    end
  end
end
