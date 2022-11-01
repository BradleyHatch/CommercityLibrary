# frozen_string_literal: true

namespace :c do
  namespace :background_jobs do
    task set_status: :environment do
      C::UpdateBackgroundStatusJob.perform_now
    end
  end
end
