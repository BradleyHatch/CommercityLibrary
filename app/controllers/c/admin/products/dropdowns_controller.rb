# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class DropdownsController < AdminController
        load_and_authorize_resource class: C::Product::Dropdown

        def index
          @dropdowns = filter_and_paginate(@dropdowns, 'name asc', 250)
        end

        def create
          if @dropdown.save
            redirect_to product_dropdowns_path
          else
            render :new
          end
        end

        def update
          if @dropdown.update(dropdown_params)
            redirect_to product_dropdowns_path
          else
            render :edit
          end
        end

        def destroy
          @dropdown.destroy
          redirect_to product_dropdowns_path, notice: 'Dropdown Deleted'
        end

        private

        def dropdown_params
          params.require(:product_dropdown).permit(:name, :active, category_ids: [], variant_ids: [])
        end
      end
    end
  end
end
