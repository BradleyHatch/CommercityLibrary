# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class CollectionsController < AdminController
      load_and_authorize_resource class: C::Collection

      def index
        @collections = filter_and_paginate(@collections, 'name asc', 250)
      end

      def create
        if @collection.save
          redirect_to collections_path, notice: 'Collection created'
        else
          render :new
        end
      end

      def update
        if @collection.update(collection_params)
          redirect_to collections_path, notice: 'Collection updated'
        else
          render :edit
        end
      end

      def remove_image
        @collection.remove_image = true
        @collection.save!
        redirect_to [:edit, @collection]
      end

      def destroy
        @collection.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:collections] }
        end
      end

      def confirm_destroy; end

      private

      def collection_params
        params.require(:collection).permit(
          :name, :body, :image, :image_alt, :slug, :title, :meta_description, :collection_type,  variant_ids: [], category_ids: []
        )
      end
    end
  end
end
