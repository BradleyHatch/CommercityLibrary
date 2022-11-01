# frozen_string_literal: true
class CreateCAuthorRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :c_author_records do |t|
      t.references :user
      t.references :authored, polymorphic: true

      t.timestamps
    end
  end
end
