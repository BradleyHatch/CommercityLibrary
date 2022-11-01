# frozen_string_literal: true

module C
  class BackgroundJob < ApplicationRecord
    scope :potential_failures, (-> { where('last_ran < ?', 20.minutes.ago) })
    enum status: %i[processing warning completed failed]

    # This is a demo assoc - maybe like this - tie it into a job
    has_many :c_amazon_processing_queues, class_name: 'C::AmazonProcessingQueue'

    after_commit do
      BackgroundJobsChannel.update_all
    end

    validates :status, presence: true

    def set_status
      return if last_ran.blank?
      self.status = if last_ran < 50.minutes.ago
                      :failed
                    elsif last_ran < 20.minutes.ago
                      :warning
                    else
                      :completed
                    end
    end

    def set_status!
      set_status
      save
    end

    def completed!
      update(status: :completed, last_ran: Time.zone.now)
    end

    def failed!
      update(status: :failed, last_ran: Time.zone.now)
    end

    def as_json(options = {})
      super(options.merge(methods: :status))
    end

    ## To be used around code to be monitored
    # E.g.
    #
    # C::BackgroundJob.process('Foobar') do |job|
    #   object.do_some_job
    # end
    def self.process(name, options = {})
      self_destruct = options.delete(:self_destruct) || false
      job = find_or_initialize_by(name: name) { |j| j.assign_attributes(options) }
      job.status = :processing
      job.save!
      begin
        result = yield job
        self_destruct ? job.destroy : job.completed!
        result
      rescue => e
        job.failed!
        logger.error(e.message)

        whitelist = [
          # this one is sent if the ebay auth token has expired
          "undefined method `[]' for nil:NilClass",
        ]

        e_as_string = e.to_s

        should_send = false

        whitelist.each { |item| 
          if e_as_string.include?(item)
            should_send = true
          end
          if should_send
            break
          end
        }

        if should_send
          ActionMailer::Base.mail(
            from: C.errors_email,
            to: C.errors_email,
            subject: "#{C.store_name} Background Task #{name} Failure",
            body: e_as_string + "\n\n" + e.backtrace.join("\n\n")
          ).deliver
        end

        raise e
      end
    end
  end
end
