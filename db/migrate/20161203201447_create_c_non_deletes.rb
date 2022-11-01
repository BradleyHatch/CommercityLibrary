# frozen_string_literal: true
class CreateCNonDeletes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_non_deletes do |t|
      t.boolean :deleted, default: false
      t.references :non_deletable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
