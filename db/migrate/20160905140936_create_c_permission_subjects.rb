# frozen_string_literal: true
class CreateCPermissionSubjects < ActiveRecord::Migration[5.0]
  def change
    create_table :c_permission_subjects do |t|
      t.string :name
      t.text :body

      t.string :subject_type
      t.integer :subject_id

      t.timestamps
    end
  end
end
