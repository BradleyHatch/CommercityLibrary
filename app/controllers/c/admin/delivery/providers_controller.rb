# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Delivery
      class ProvidersController < AdminController
        load_and_authorize_resource class: C::Delivery::Provider

        def index; end

        def new; end

        def create
          if @provider.save
            redirect_to delivery_providers_path,
                        notice: 'Delivery Service created'
          else
            render :new
          end
        end

        def edit; end

        def update
          if @provider.update(provider_params)
            redirect_to delivery_providers_path,
                        notice: 'Delivery Service updated'
          else
            render :edit
          end
        end

        def destroy
          @provider.destroy
          redirect_to delivery_providers_path, notice: 'Delivery Service deleted'
        end

        private

        def provider_params
          params.require(:delivery_provider).permit(:name, :tracking_link)
        end
      end
    end
  end
end
