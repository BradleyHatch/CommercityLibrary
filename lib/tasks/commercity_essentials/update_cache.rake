# frozen_string_literal: true

namespace :c do
  task update_cache: :environment do
    C::UpdateCacheJob.perform_now
  end
end
