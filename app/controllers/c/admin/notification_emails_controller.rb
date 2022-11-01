# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class NotificationEmailsController < AdminController
      load_and_authorize_resource class: C::NotificationEmail

      def index
        @notification_emails = filter_and_paginate(@notification_emails, 'email asc')
      end

      def create
        if @notification_email.save
          redirect_to notification_emails_path, notice: 'Notification Email created'
        else
          render :new
        end
      end

      def update
        if @notification_email.update(notification_email_params)
          redirect_to notification_emails_path, notice: 'Notification Email created'
        else
          render :edit
        end
      end

      def destroy
        if @notification_email.destroy
          flash[:success] = 'Notification email deleted'
          redirect_to action: :index
        else
          flash.now[:error] = 'Notification email could not be deleted'
          render :edit
        end
      end

      def confirm_destroy; end

      private

      def notification_email_params
        params.require(:notification_email).permit(:email, :orders, :enquiries)
      end
    end
  end
end
