# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class CustomersController < AdminController
      load_and_authorize_resource class: C::Customer

      def index
        # if params["q"].blank? 
        #   if params["q"]["s"].present?
        #     if params["q"]["s"] == 'name asc' 
        #       params["q"]["s"] = 'LOWER(name) asc'
        #     end
        #     if params["q"]["s"] == 'name desc' 
        #       params["q"]["s"] = 'LOWER(name) desc'
        #     end
        #   end
        # end
          
        @customers = filter_and_paginate(@customers, 'LOWER(name) asc')
      end

      def new
        if @customer.account.blank?
          @customer.build_account 
        end
      end

      def edit
        if @customer.account.blank?
          @customer.build_account 
        end
      end

      def create
        if @customer.save

          if params[:customer][:custom_values]
            @customer.custom_values = (params[:customer][:custom_values])
          end

          redirect_to [:customers], notice: 'Customer Created'
        else
          render :new
        end
      end

      def update
        if params[:customer][:custom_values]
          @customer.custom_values = (params[:customer][:custom_values])
        end

        if @customer.update(customer_params)
          redirect_to [:customers], notice: 'Customer updated'
        else
          render :edit
        end
      end

      # Build all scope pages
      scope_filters = []
      scope_filters << C::Customer.channels.keys
      scope_filters << 'companies'
      scope_filters.flatten.each do |method_name|
        define_method method_name do
          @customers = C::Customer.send(method_name)
          render :index
        end
      end

      def bulk_actions
        case params[:bulk_action]
        when 'destroy'
          redirect_to(confirm_mass_destroy_customers_path(
                        ids: params[:customer]
          )) && return
        else
          flash[:notice] = 'Nothing to update'
        end
        redirect_back(fallback_location: customers_path)
      end

      def confirm_mass_destroy
        @objects = C::Customer.where(id: params[:ids])
      end

      def mass_destroy
        ids = params[:ids].split(' ')
        count = ids.length
        begin
          C::Customer.where(id: ids).destroy_all
          flash[:notice] = "Deleted #{count} customers"
        rescue ActiveRecord::DeleteRestrictionError
          flash[:error] = "Can't delete customers with orders"
        end
        redirect_to customers_path
      end

      def destroy
        @customer.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:customers] }
        end
      end

      def show
        respond_to do |format|
          format.json { render json: @customer }
        end
      end

      private

      def customer_params
        temp_params = params.require(:customer).permit(
          :name, :email, :company, :phone,
          :mobile, :fax, :password,
          :password_confirmation,
          :current_password,
          :account_type,
          C::Customer::CUSTOM_VALUE_ATTRIBUTES,
          account_attributes: %i[id email account_type payment_type password]
        )

        if temp_params[:account_attributes] && temp_params[:account_attributes][:password].blank?
          temp_params[:account_attributes].delete(:password)
        end
        temp_params
      end

    end
  end
end
