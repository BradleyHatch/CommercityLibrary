# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  class Admin::XeroSessionsController < ApplicationController
    include C::XeroSessionsHelper

    def new
      session.delete(:xero_access)
      request_token = xero_client.request_token(
        oauth_callback: xero_sessions_url(request.GET)
      )
      session[:xero_request] = {
        token: request_token.token,
        secret: request_token.secret
      }
      redirect_to request_token.authorize_url
    end

    def create
      xero_client.authorize_from_request(
        session[:xero_request]['token'],
        session[:xero_request]['secret'],
        oauth_verifier: params[:oauth_verifier]
      )
      session.delete(:xero_request)

      session[:xero_access] = {
        token: xero_client.access_token.token,
        key: xero_client.access_token.secret
      }

      if params[:type] == 'order'
        redirect_to xero_export_order_sale_path(params[:target_id])
      elsif params[:type] == 'bulk_order'
        redirect_to bulk_xero_export_order_sales_path(bulk_actions: :xero, sale: params[:target_id])
      else
        redirect_to admin_path
      end
    end

    def destroy
      session.delete(:xero_access)
      session.delete(:xero_request)
      redirect_to admin_path
    end
  end
end
