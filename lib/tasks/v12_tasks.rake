# frozen_string_literal: true

namespace :c do
  namespace :v12 do
    task get_payments: :environment do
      C::V12PaymentsJob.new.perform(:process_unpaid_payments)
    end
  end
end
