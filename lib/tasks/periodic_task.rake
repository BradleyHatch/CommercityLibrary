# frozen_string_literal: true

namespace :c do
  task periodic_task: :environment do
    task_list = C.periodic_task_list
    task_list << 'c:commercity_engine'
    task_list.each do |t|
      begin
        Rake::Task[t].invoke
      rescue => e
        ActionMailer::Base.mail(
          from: C.errors_email,
          to: C.errors_email,
          subject: "#{C.store_name} Periodic #{t} Failure",
          body: e.to_s + "\n\n" + e.backtrace.join("\n\n")
        ).deliver
      end
    end
  end
end
