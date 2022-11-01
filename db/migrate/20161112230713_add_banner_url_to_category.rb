# frozen_string_literal: true
class AddBannerUrlToCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :c_categories, :banner_url, :string
    add_column :c_categories, :alt_tag, :string
  end
end
