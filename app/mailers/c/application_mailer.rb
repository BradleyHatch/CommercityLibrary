# frozen_string_literal: true

module C
  class ApplicationMailer < ActionMailer::Base
    default from: C.email_from ? C.email_from : "#{C.store_name}<notifications@#{C.domain_name}>"
    layout 'c/mailer'
  end
end
