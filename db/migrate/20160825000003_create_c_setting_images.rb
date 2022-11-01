# frozen_string_literal: true
class CreateCSettingImages < ActiveRecord::Migration[5.0]
  def change
    create_table :c_setting_type_images do |t|
      t.string :value
      t.string :default
      t.string :default_string

      t.timestamps
    end
  end
end
