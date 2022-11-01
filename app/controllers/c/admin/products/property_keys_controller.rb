# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class PropertyKeysController < AdminController
        load_and_authorize_resource class: C::Product::PropertyKey

        def create
          if @property_key.update(property_key_params)
            redirect_to product_property_keys_path
          else
            render :new
          end
        end

        def update
          if @property_key.update(property_key_params)
            if params[:values]
              params[:values].each do |value_string, attrs|
                # C::Product::PropertyValue.where(value: value_string).update_all(active: attrs["active"].present?)
                if attrs["_destroy"].present?
                  C::Product::PropertyValue.where(value: value_string).destroy_all
                end
              end
            end
            redirect_to product_property_keys_path
          else
            render :edit
          end
        end

        def destroy
          @property_key.destroy
          respond_to do |format|
            format.js
            format.html { redirect_to product_property_keys_path }
          end
        end

        def confirm_destroy; end

        private

        def property_key_params
          params.require(:product_property_key).permit(:id, :key, :display)
        end
      end
    end
  end
end
