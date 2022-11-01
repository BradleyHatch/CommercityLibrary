# frozen_string_literal: true
class CreateCPageInfos < ActiveRecord::Migration[5.0]
  def change
    create_table :c_page_infos do |t|
      t.string      :title
      t.text        :meta_description
      t.string      :url_alias
      t.boolean     :published,         default: true
      t.boolean     :protected,         default: false
      t.references  :page,              polymorphic: true
      t.string      :page_type
      t.boolean     :home_page, default: false
      t.integer     :order

      t.timestamps
    end
  end
end
