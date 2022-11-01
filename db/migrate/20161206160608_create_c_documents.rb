# frozen_string_literal: true
class CreateCDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :c_documents do |t|
      t.string :name
      t.string :document
      t.string :documentable_type
      t.integer :documentable_id

      t.timestamps
    end
  end
end
