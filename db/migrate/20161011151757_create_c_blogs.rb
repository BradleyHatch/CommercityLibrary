# frozen_string_literal: true
class CreateCBlogs < ActiveRecord::Migration[5.0]
  def change
    create_table :c_blogs do |t|
      t.string   :name
      t.text     :body

      t.timestamps
    end
  end
end
