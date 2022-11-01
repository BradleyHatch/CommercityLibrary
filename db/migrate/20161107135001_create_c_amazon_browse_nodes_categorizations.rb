# frozen_string_literal: true
class CreateCAmazonBrowseNodesCategorizations < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_browse_nodes_categorizations do |t|
      t.belongs_to :amazon_channel, index: { name: 'index_abnc_on_amazon_channel' }
      t.belongs_to :amazon_browse_node, index: { name: 'index_abnc_on_amazon_browse_node' }

      t.timestamps
    end
  end
end
