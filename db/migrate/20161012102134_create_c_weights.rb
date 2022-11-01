# frozen_string_literal: true
class CreateCWeights < ActiveRecord::Migration[5.0]
  def change
    create_table :c_weights do |t|
      t.integer :value
      t.references :orderable, polymorphic: true

      t.timestamps
    end
  end
end
