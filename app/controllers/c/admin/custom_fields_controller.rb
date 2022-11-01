# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class CustomFieldsController < AdminController
      load_and_authorize_resource class: C::CustomField

      def index
        @custom_fields = filter_and_paginate(@custom_fields, 'name asc')
      end

      def create
        if @custom_field.save
          redirect_to [:custom_fields], notice: 'Custom Field Created'
        else
          render :new
        end
      end

      def update
        if @custom_field.update(custom_field_params)
          redirect_to [:custom_fields], notice: 'Custom Field Updated'
        else
          render :edit
        end
      end

      def destroy
        @custom_field.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:custom_fields] }
        end
      end

      private

      def custom_field_params
        params.require(:custom_field).permit(:name, :data_type, :class_type)
      end
    end
  end
end
