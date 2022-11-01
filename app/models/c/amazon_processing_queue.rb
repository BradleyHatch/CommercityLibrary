# frozen_string_literal: true

module C
  class AmazonProcessingQueue < ApplicationRecord
    # A FIFO Queue in the database to track status of an Amazon feed
    # submission flow

    scope :queue_order, (lambda {
                           where(job_status: :processing)
                             .order(created_at: :asc)
                         })

    enum feed_type: %i[product
                       price
                       inventory
                       image
                       shipping
                       acknowledgement
                       fulfillment]

    enum job_status: %i[processing complete failed]

    has_and_belongs_to_many :products,
                            class_name: 'C::Product::Variant',
                            association_foreign_key: 'product_id',
                            join_table: 'c_apqs_products'

    validates :feed_id, presence: true
    validates :feed_type, presence: true

    def mark_complete
      update(completed_at: DateTime.now, job_status: :complete)
      self
    end

    def mark_failed(reason)
      update(completed_at: DateTime.now, job_status: :failed,
             failure_message: reason)
      self
    end

    def process
      logger.info "Processing APQ ID: #{id}"
    end

    def failure_messages_for(product)
      extract_failure_messages.select do |m|
        (!m['AdditionalInfo'].nil? && m['AdditionalInfo']['SKU'] == product.sku) ||
          (!m['additional_info'].nil? && m['additional_info']['sku'] == product.sku)
      end
    end

    def product_failed?(product)
      failure_messages_for(product).present?
    end

    def extract_failure_messages
      return [] if failure_message.blank?
      data = JSON.parse(failure_message)
      [data['ProcessingReport']['Result']].flatten
    rescue
      # WHAT?
      [JSON.parse(failure_message)['responses'].map(&:last)].flatten
    end

    def successful_products
      products.reject { |p| product_failed?(p) }
    end

    def cache_product_results
      products.each do |product|
        if (messages = failure_messages_for(product)).present?
          product.master.cache_amazon_results(false, messages)
        else
          product.master.cache_amazon_results(true)
        end
      end
    end

    # Class Methods
    def self.next
      processing_jobs.first
    end

    def self.push(products, feed_id, feed_type, feed_body = nil)
      apq = new(feed_id: feed_id, feed_type: feed_type, job_status:
                :processing, submitted_at: DateTime.now, feed_body: feed_body)
      apq.products = products
      apq.save!
    end

    def self.processing_jobs
      queue_order
    end
  end
end
