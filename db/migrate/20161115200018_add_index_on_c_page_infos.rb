# frozen_string_literal: true
class AddIndexOnCPageInfos < ActiveRecord::Migration[5.0]
  def change
    add_index :c_page_infos, :url_alias
  end
end
