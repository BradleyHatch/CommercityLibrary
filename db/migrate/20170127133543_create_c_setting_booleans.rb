# frozen_string_literal: true
class CreateCSettingBooleans < ActiveRecord::Migration[5.0]
  def change
    create_table :c_setting_type_booleans do |t|
      t.boolean :value
      t.boolean :default

      t.timestamps
    end
  end
end
