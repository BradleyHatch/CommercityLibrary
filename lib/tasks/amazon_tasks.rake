# frozen_string_literal: true

namespace :c do
  namespace :amazon do
    task check_processing_queue: :environment do
      if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
        C::AmazonPipeline.status_all
      else
        C::AmazonJob.perform_now('check_feed_status', nil)
      end
    end

    task push_updated_products: :environment do
      if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
        C::AmazonPipeline.push_changed
      else
        C::AmazonJob.perform_now('push_updated_products', nil)
      end
    end

    task update_inventory: :environment do
      if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
        C::AmazonPipeline.push_changed
      else
        C::AmazonJob.perform_now('push_updated_inventory', nil)
      end
    end

    task get_orders: :environment do
      C::AmazonOrderJob.perform_now('pull_and_process_orders', 7.days.ago)
    end

    task get_international_orders: :environment do
      marketplace_list = [
        'A1F83G8C2ARO7P',  # UK
        'A1PA6795UKMFR9',  # DE
        'A1RKKUPIHCS9HS',  # ES
        'A13V1IB3VIYZZH',  # FR
        'APJ6JRA9NG5V4',    # IT
        'A1805IZSGTT6HS',   # NL
        'A2NODRKZP88ZB9',   # SE
      ]

      marketplace_list.each do |marketplace_id|
        puts "Processing Marketplace: #{marketplace_id}"
        C::AmazonOrderJob.new.perform('pull_and_process_orders', 7.days.ago,
                                      marketplace_id: marketplace_id)
      end
    end

    task prune_processing_queues: :environment do
      C::AmazonProcessingQueue.where('updated_at < ?', 1.week.ago).destroy_all
      C::AmazonProcessingQueue.inventory.where('updated_at < ?', 3.hours.ago).destroy_all
    end
  end
end
