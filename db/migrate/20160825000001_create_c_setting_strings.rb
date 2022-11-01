# frozen_string_literal: true
class CreateCSettingStrings < ActiveRecord::Migration[5.0]
  def change
    create_table :c_setting_type_strings do |t|
      t.string :value
      t.string :default

      t.timestamps
    end
  end
end
