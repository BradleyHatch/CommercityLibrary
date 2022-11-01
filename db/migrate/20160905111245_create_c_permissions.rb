# frozen_string_literal: true
class CreateCPermissions < ActiveRecord::Migration[5.0]
  def change
    create_table :c_permissions do |t|
      t.references :role
      t.references :permission_subject

      t.boolean :read
      t.boolean :new
      t.boolean :edit
      t.boolean :remove

      t.timestamps
    end
  end
end
