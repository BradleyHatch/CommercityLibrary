# frozen_string_literal: true
class CreateCRedirects < ActiveRecord::Migration[5.0]
  def change
    create_table :c_redirects do |t|
      t.string :old_url
      t.string :new_url
      t.datetime :last_used
      t.integer :used_counter, default: 0

      t.timestamps
    end
  end
end
