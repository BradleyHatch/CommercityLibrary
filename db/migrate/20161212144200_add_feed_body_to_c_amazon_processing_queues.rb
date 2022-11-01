# frozen_string_literal: true
class AddFeedBodyToCAmazonProcessingQueues < ActiveRecord::Migration[5.0]
  def change
    add_column :c_amazon_processing_queues, :feed_body, :text
  end
end
