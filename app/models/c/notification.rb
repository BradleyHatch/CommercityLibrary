module C
  class Notification < ApplicationRecord
    belongs_to :notifiable, polymorphic: true

    validates :notifiable, presence: true

    scope :read, -> { where read: true }
    scope :unread, -> { where read: false }
    scope :ordered, -> { order created_at: :desc }

    def display_name
      case notifiable_type
      when 'C::Enquiry'
        notifiable.body&.truncate(30)
      when 'C::Message'
        notifiable.subject
      when 'C::Product::Question'
        notifiable.display_subject
      else
        ''
      end
    end

    def display_type
      case notifiable_type
      when 'C::Enquiry'
        'Enquiry'
      when 'C::Message'
        'Message'
      when 'C::Product::Question'
        'Product Question'
      else
        ''
      end
    end
  end
end
