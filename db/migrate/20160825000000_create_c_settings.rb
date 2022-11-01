# frozen_string_literal: true
class CreateCSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :c_settings do |t|
      t.string :key
      t.references :data, polymorphic: true
      t.references :setting_group

      t.timestamps
    end
    add_index :c_settings, :key, unique: true
    add_index :c_settings, [:data_id, :data_type], unique: true
  end
end
