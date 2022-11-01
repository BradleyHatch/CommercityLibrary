# frozen_string_literal: true

module C
  class Message < ApplicationRecord

    include Notifiable

    after_create :notify

    enum source: %i[web ebay amazon]

  end
end
