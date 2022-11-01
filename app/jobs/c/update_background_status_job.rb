# frozen_string_literal: true

module C
  class UpdateBackgroundStatusJob < ApplicationJob
    queue_as :default

    def perform(*_args)
      C::BackgroundJob.potential_failures.each(&:set_status!)
    end
  end
end
