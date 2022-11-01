# frozen_string_literal: true

module C
  class OrderMailer < ApplicationMailer
    helper 'c/presenter'

    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.order_mailer.notify_store.subject
    #
    def notify_store(order)
      @order = order
      @email = order_notification_recipient_addresses
      @title = "A purchase has been made (#{@order.order_number})"
      mail to: @email, subject: 'New Order'
    end

    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.order_mailer.notify_customer.subject
    #
    def notify_customer(order)
      @order = order
      @email = @order.email
      @unsub_email = @email
      @title = "Thank you for your order (#{@order.order_number})"
      mail to: @email, subject: 'Thank you for your order'
    end

    def dispatch_nofitication(order)
      @order = order
      @email = @order.email
      @unsub_email = @email
      @title = @order.click_and_collect? ? "Your order (#{@order.order_number}) is ready for collection" : "Your order (#{@order.order_number}) has been dispatched"
      mail to: @email, subject: @order.click_and_collect? ? "Order (#{@order.order_number}) is ready for collection" : "Order (#{@order.order_number}) has been dispatched"
    end

    def tracking_email(order)
      @order = order
      @email = @order.email
      @unsub_email = @email
      @title = "Tracking information for your order (#{@order.order_number})"
      mail to: @email, subject: @title
    end

    def send_abandon_mailout(cart, rich_body, text_body, voucher=nil)
      @email = cart.customer.email
      @cart = cart
      @rich_body = rich_body
      @text_body = text_body
      @voucher = voucher
      mail to: @email, subject: "Complete your #{C.store_name} purchase#{' - ' + @voucher.breakdown if @voucher}"
    end

    def send_google_review_prompt(order)
      @order = order
      @email = @order.email
      @name = @order.name
      mail to: @email, subject: "Please leave us a review"
    end

    def send_voucher_email(order)
      @order = order
      @voucher = order.product_voucher
      @email = @order.email

      if !@voucher
        return
      end

      mail to: @email, subject: "Enjoy 15% off your next order"
    end

    def notify_voucher_used_email(order)
      if C.vouchers_to_notify_on_use_ids.blank? || C.notify_voucher_used_email.blank?
        return
      end

      voucher_ids = order.items.pluck(:voucher_id)
      used_voucher_ids = Array.wrap(C.vouchers_to_notify_on_use_ids) & voucher_ids

      if used_voucher_ids.empty?
        return
      end

      @vouchers = C::Product::Voucher.where(id: used_voucher_ids.compact)

      @order = order
      @email = C.notify_voucher_used_email
      mail to: @email, subject:  "Purchase has been made using your voucher code"
    end

    private

    def order_notification_recipient_addresses
      C::NotificationEmail.order_recipients
    end
  end
end
