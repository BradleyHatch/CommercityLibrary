# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class OptionsController < AdminController
        load_and_authorize_resource class: C::Product::Option

        def new
          @option.price = C::Price.new
        end

        def index
          @options = filter_and_paginate(@options, 'name asc', 250)
        end

        def create
          if @option.save
            redirect_to [:edit, @option]
          else
            @option.price = C::Price.new
            render :new
          end
        end

        def update
          if @option.update(option_params)
            redirect_to [:edit, @option]
          else
            render :edit
          end
        end

        def destroy
          @option.destroy
          redirect_to product_options_path, notice: 'Option Deleted'
        end

        private

        def option_params
          params.require(:product_option).permit(
            :name, :compulsory, price_attributes: %i[id without_tax with_tax tax_rate override]
          )
        end
      end
    end
  end
end
