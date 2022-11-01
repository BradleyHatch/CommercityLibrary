# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class BrandsController < AdminController
      load_and_authorize_resource class: C::Brand

      def index
        @brands = filter_and_paginate(@brands, 'name asc', 250)
      end

      def create
        if @brand.save
          redirect_to brands_path, notice: 'Brand Created'
        else
          render :new
        end
      end

      def update
        if @brand.update(brand_params)
          redirect_to brands_path, notice: 'Brand Updated'
        else
          render :edit
        end
      end

      def destroy
        @brand.products.destroy_all if params[:destroy_products]
        @brand.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to [:brands] }
        end
      end

      def confirm_destroy; end

      def bulk_actions
        case params[:bulk_action]
        when 'delete'
          params[:brand].each { |id| C::Brand.find(id).destroy }
        else
          flash[:notice] = 'Nothing to update'
        end
        redirect_back(fallback_location: order_sales_path)
      end

      private

      def brand_params
        params.require(:brand).permit(
          :name, :body, :internal_id, :url, :image,
          :manufacturer, :supplier, :featured, :in_menu,
          :slug, page_info_attributes: %i[id title meta_description]
        )
      end
    end
  end
end
