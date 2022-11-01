# frozen_string_literal: true

module C
  class UpdateCacheJob < ApplicationJob
    # queue_as :default

    def perform(*args)
      _options = args
      variant_ids = C::Product::Variant.where('updated_at > ?', 1.hour.ago).ids
      master_ids = C::Product::Master.where('updated_at > ?', 1.hour.ago).ids
      master_variant_ids = C::Product::Variant.where(master_id: master_ids).ids
      ids = (variant_ids & master_variant_ids).compact
      variants_to_update = C::Product::Variant.where(id: ids)
      C::BackgroundJob.process('Active Cache',
                               job_size: variants_to_update.count,
                               job_processed_count: 0) do |job|

        variants_to_update.each_with_index do |product, i|
          product.build_cache_fields
          job.update!(job_processed_count: i + 1)
        end
      end
    end
  end
end
