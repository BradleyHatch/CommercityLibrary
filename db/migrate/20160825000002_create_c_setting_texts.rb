# frozen_string_literal: true
class CreateCSettingTexts < ActiveRecord::Migration[5.0]
  def change
    create_table :c_setting_type_texts do |t|
      t.string :value
      t.string :default

      t.timestamps
    end
  end
end
