# frozen_string_literal: true
class AddPreviewBodyToCPages < ActiveRecord::Migration[5.0]
  def change
    add_column :c_pages, :preview_body, :text
    add_column :c_services, :preview_body, :text
    add_column :c_blogs, :preview_body, :text
  end
end
