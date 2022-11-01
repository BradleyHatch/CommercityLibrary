# frozen_string_literal: true
class CreateCSettingGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :c_setting_groups do |t|
      t.string :name
      t.string :machine_name
      t.text :body

      t.timestamps
    end
  end
end
