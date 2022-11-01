# frozen_string_literal: true
class CreateCAmazonProcessingQueues < ActiveRecord::Migration[5.0]
  def change
    create_table :c_amazon_processing_queues do |t|
      t.string :feed_id
      t.integer :feed_type
      t.integer :job_status

      t.datetime :submitted_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
