# frozen_string_literal: true

module C
  class Order::Tracking < ApplicationRecord
    belongs_to :delivery, class_name: 'C::Order::Delivery'

    after_save :try_to_send_email_out

    def try_to_send_email_out
      if number.blank? || sale.blank?
        return
      end

      return

      sale.send_tracking_emails
    end

    def sale
      delivery.sale
    end

  end
end
