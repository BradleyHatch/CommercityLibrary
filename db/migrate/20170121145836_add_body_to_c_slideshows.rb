# frozen_string_literal: true
class AddBodyToCSlideshows < ActiveRecord::Migration[5.0]
  def change
    add_column :c_slideshows, :body, :text
  end
end
