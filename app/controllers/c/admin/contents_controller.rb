# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class ContentsController < AdminController
      load_and_authorize_resource class: C::Content

      # required for dropzone to work
      skip_before_action :verify_authenticity_token, only: :dropzone_image

      def index
        @contents = filter_and_paginate(@contents, 'created_at desc')
      end

      def new
        @content.content_type = params[:content_type] || :basic_page
      end

      C.content_sections.each

      C.content_sections.each do |content|
        define_method content do
          @contents = filter_and_paginate(C::Content.send(content), 'created_at desc')
          render :index
        end
      end

      def create
        if @content.save
          redirect_to [:edit, @content], notice: 'Content created'
        else
          render :new
        end
      end

      def update
        if @content.update(content_params)
          redirect_to [:edit, @content], notice: 'Content updated'
        else
          render :edit
        end
      end

      def destroy
        @content.destroy unless @content.protected
        respond_to do |format|
          format.js
          format.html { redirect_to [@content.content_type, :contents] }
        end
      end

      # dropzone methods

      def dropzone_image
        @content.images.create(image: params[:file])
      end

      def destroy_image
        @content.images.find_by(id: params[:image_id]).destroy
        respond_to do |format|
          format.js
        end
      end

      def reload_images
        @obj = @content
        @model_name = 'content'
        respond_to do |format|
          format.js
        end
      end

      def set_featured_image
        @obj = @content
        @model_name = 'content'
        img = C::Image.find(params[:image_id])
        @obj.images.where.not(id: img.id).update_all(featured_image: false)
        img.toggle!(:featured_image)
      end

      def set_preview_image
        @obj = @content
        @model_name = 'content'
        @obj.images.find_each { |image| image.update(preview_image: false) }
        C::Image.find(params[:image_id]).update(preview_image: true)
        respond_to do |format|
          format.js
        end
      end

      private

      def content_params
        params.require(:content).permit(
          :name, :body, :summary, :layout, :published, :template_group_id,
          :slug, :title, :meta_description, :parent_id, :content_type, :template, new_images: [],
                                                                                  documents_attributes: %i[id name document _destroy],
                                                                                  new_documents: [],
                                                                                  images_attributes: %i[_destroy
                                                                                                        id
                                                                                                        alt
                                                                                                        caption
                                                                                                        image
                                                                                                        image_cache
                                                                                                        feature_image
                                                                                                        preview_image
                                                                                                        weight
                                                                                                        featured_image]
        )
      end
    end
  end
end
