# frozen_string_literal: true
class CreateCProductChannelAmazonSearchTerms < ActiveRecord::Migration[5.0]
  def change
    create_table :c_product_channel_amazon_search_terms do |t|
      t.string :term
      t.belongs_to :product_channel, index: { name: 'index_amzn_search_terms_on_product_channel_id' }

      t.timestamps
    end
  end
end
