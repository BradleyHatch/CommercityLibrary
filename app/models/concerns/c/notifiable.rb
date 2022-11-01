# frozen_string_literal: true

module C
  module Notifiable
    extend ActiveSupport::Concern

    included do
      has_one :notification, as: :notifiable, dependent: :destroy

      def notify
        build_notification
        notification.save!
      end
    end
  end
end
