# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class RedirectsController < AdminController
      load_and_authorize_resource class: C::Redirect
      before_action :set_redirect, only: %i[edit update destroy]

      def index
        @redirects = filter_and_paginate(@redirects, 'old_url asc')
      end

      def create
        if @redirect.save
          redirect_to redirects_path, notice: 'Redirect Created'
        else
          render :new
        end
      end

      def update
        if @redirect.update(redirect_params)
          redirect_to redirects_path, notice: 'Redirect Updated'
        else
          render :edit
        end
      end

      def destroy
        @redirect.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:redirect] }
        end
      end

      def confirm_destroy; end

      def bulk_actions
        @redirects = C::Redirect.where(id: params[:redirect])
        action = @redirects.bulk_action(params[:bulk_actions])
        redirect_back(fallback_location: order_sales_path, notice: action)
      end

      private

      def set_redirect
        @redirect = Redirect.find(params[:id])
      end

      def redirect_params
        params.require(:redirect).permit(:old_url, :new_url,
                                         :last_used, :used_counter)
      end
    end
  end
end
