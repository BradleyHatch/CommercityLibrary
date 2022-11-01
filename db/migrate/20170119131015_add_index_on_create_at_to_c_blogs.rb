# frozen_string_literal: true
class AddIndexOnCreateAtToCBlogs < ActiveRecord::Migration[5.0]
  def change
    add_index(:c_blogs, :created_at)
  end
end
