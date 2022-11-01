# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class EnquiriesController < AdminController
      load_and_authorize_resource class: C::Enquiry

      def index
        @enquiries = filter_and_paginate(@enquiries, 'created_at desc')
      end

      def show; end

      def destroy
        @enquiry.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to enquiries_path }
        end
      end
    end
  end
end
