# frozen_string_literal: true

module C
  class Enquiry < ApplicationRecord
    include Notifiable

    after_create :notify

    validates :name, presence: true

    scope :ordered, -> { order created_at: :desc }

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email,
              presence: true,
              length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX }

    INDEX_TABLE = {
      'Name': { call: 'name' },
      'Email': { call: 'email' },
      'Message': { call: 'body' }
    }.freeze
  end
end
