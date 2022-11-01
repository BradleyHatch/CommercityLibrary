module C
  class NotificationEmail < ApplicationRecord
    # validations
    validates :email, uniqueness: true, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: 'is not a valid email address' }

    def self.order_recipients
      recipients = self.where(orders: true).pluck(:email)
      if recipients.empty?
        self.default_recipients
      else
        recipients
      end
    end

    def self.enquiry_recipients
      recipients = self.where(enquiries: true).pluck(:email)
      if recipients.empty?
        self.default_recipients
      else
        recipients
      end
    end

    def self.default_recipients
      C.order_notification_email
    end

    INDEX_TABLE = {
      'Email': {
        link: {
          name: {
            call: 'email'
          },
          options: '[:edit, object]'
        },
        sort: 'email'
      },
      'Receives orders emails': {
        call: 'orders'
      },
      'Receives enquiries emails': {
        call: 'enquiries'
      },
      'Edit': {
        link: {
          name: {
            text: 'edit'
          }, options: '[:edit, object]'
        }
      }
    }.freeze

  end
end
