# frozen_string_literal: true

module C
  class CsvImport < ApplicationJob
    queue_as :default

    def perform(*args)
      args.each(&:import!)
    end
  end
end
