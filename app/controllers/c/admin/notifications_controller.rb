# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class NotificationsController < AdminController
      load_and_authorize_resource class: C::Notification

      def index
        @notifications = filter_and_paginate(@notifications, 'created_at desc')
      end

      def show
        @notifications = filter_and_paginate(C::Notification.all, 'created_at desc')
        @notification.update!(read: true)
      end

      def destroy
        @notification.destroy
        redirect_to notifications_path
      end

      def render_message
        render html: @notification.notifiable.body.html_safe
      end

    end
  end
end
