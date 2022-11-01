# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Delivery
      class ServicesController < AdminController
        load_and_authorize_resource class: C::Delivery::Service

        def index
          @services = @services.web
        end

        def new; end

        def create
          if @service.save
            redirect_to delivery_services_path,
                        notice: 'Delivery Service created'
          else
            render :new
          end
        end

        def edit; end

        def update
          if @service.update(service_params)
            if params['commit'] == 'Save'
              render :edit
            else
              redirect_to delivery_services_path,
                          notice: 'Delivery Service updated'
            end
          else
            render :edit
          end
        end

        def destroy
          @service.destroy
          redirect_to delivery_services_path,
                      notice: 'Delivery Service deleted'
        end

        def sort
          @services = C::Delivery::Service.all
          @services.update_order(params[:service])
          respond_to do |format|
            format.js { head :ok, content_type: 'text/html' }
          end
        end

        private

        def service_params
          params.require(:delivery_service).permit(
            :name,
            :display_name,
            :channel,
            :tax_rate,
            :provider_id,
            :click_and_collect,
            rules_attributes: %i[id
                                 zone_id
                                 base_price
                                 min_cart_price
                                 max_cart_price
                                 _destroy]
          )
        end
      end
    end
  end
end
