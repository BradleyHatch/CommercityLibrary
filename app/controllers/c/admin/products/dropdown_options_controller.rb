# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Products
      class DropdownOptionsController < AdminController
        before_action :set_parent
        load_and_authorize_resource class: C::Product::DropdownOption

        def index
        end
  
        def new
        end
  
        def edit
        end
  
        def create
          @dropdown_option = @dropdown.dropdown_options.new(dropdown_option_params)
          if @dropdown_option.save
            redirect_to edit_product_dropdown_product_dropdown_option_path(@dropdown.id, @dropdown_option.id), notice: 'Option created'
          else
            render :new
          end
        end
  
        def update
          if @dropdown_option.update(dropdown_option_params)
            redirect_to edit_product_dropdown_product_dropdown_option_path(@dropdown.id, @dropdown_option.id), notice: 'Option updated'
          else
            render :edit
          end
        end
  
  
        def destroy
          @dropdown_option.destroy
          respond_to do |format|
            format.js
            format.html { redirect_to edit_product_dropdown_path(@dropdown) }
          end
        end
  
  
        private
        def set_parent
          @dropdown = C::Product::Dropdown.find(params[:dropdown_id])
        end
  
        def dropdown_option_params
          params.require(:product_dropdown_option).permit(:id, :name, :value, :dropdown_id)
        end
      end
    end
  end
end
