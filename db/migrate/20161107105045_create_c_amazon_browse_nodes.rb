# frozen_string_literal: true
class CreateCAmazonBrowseNodes < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_browse_nodes do |t|
      t.string :name
      t.string :node_id
      t.string :node_path

      t.timestamps
    end
  end
end
