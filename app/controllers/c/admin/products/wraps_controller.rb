# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class WrapsController < AdminController
        load_and_authorize_resource class: C::Product::Wrap

        def index; end

        def create
          if @wrap.update(wrap_params)
            redirect_to product_wraps_path
          else
            render :new
          end
        end

        def update
          if @wrap.update(wrap_params)
            redirect_to product_wraps_path
          else
            render :edit
          end
        end

        def destroy
          @wrap.destroy
          respond_to do |format|
            format.js
            format.html { redirect_to product_wraps_path }
          end
        end

        def render_ebay_wrap
          render html: @wrap.subbed_wrap.html_safe
        end

        private

        def wrap_params
          params.require(:product_wrap).permit(:id, :name, :wrap)
        end
      end
    end
  end
end
