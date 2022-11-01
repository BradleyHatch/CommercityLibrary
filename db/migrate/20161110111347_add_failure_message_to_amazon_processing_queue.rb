# frozen_string_literal: true
class AddFailureMessageToAmazonProcessingQueue < ActiveRecord::Migration[5.0]
  def change
    add_column :c_amazon_processing_queues, :failure_message, :text
  end
end
