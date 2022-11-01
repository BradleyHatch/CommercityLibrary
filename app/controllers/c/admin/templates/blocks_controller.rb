# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class Templates::BlocksController < AdminController
      load_and_authorize_resource class: C::Template::Block
      before_action :set_parents, except: [:dropzone_image, :destroy_image, :reload_images, :set_featured_image]

      # required for dropzone to work
      skip_before_action :verify_authenticity_token, only: :dropzone_image

      def create
        @block = @region.blocks.new(block_params)
        if @block.save
          redirect_to edit_template_group_template_region_path(@group.id, @region.id), notice: 'Block created'
        else
          render :new
        end
      end

      def update
        if @block.update(block_params)
          redirect_to edit_template_group_template_region_path(@group.id, @region.id), notice: 'Block updated'
        else
          render :edit
        end
      end

      def destroy
        @block.destroy
        respond_to do |format|
          format.js
          format.html do
            redirect_to edit_template_group_template_region_path(@group.id, @region.id), notice: 'Block deleted'
          end
        end
      end

      def set_parents
        @group = C::Template::Group.find(params[:group_id])
        @region = C::Template::Region.find(params[:template_region_id])
      end

      def sort
        @blocks = @region.blocks
        @blocks.update_order(params[:region])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      # dropzone methods

      def dropzone_image
        @block.images.create(image: params[:file])
      end

      def destroy_image
        @block.images.find_by(id: params[:image_id]).destroy
        respond_to do |format|
          format.js
        end
      end

      def reload_images
        @obj = @block
        @model_name = 'block'
        respond_to do |format|
          format.js
        end
      end

      def set_featured_image
        @obj = @block
        @model_name = 'block'
        @obj.images.update_all(featured_image: false)
        C::Image.find(params[:image_id]).update(featured_image: true)
      end

      private

      def block_params
        params.require(:template_block).permit(
                                              :name,
                                              :url,
                                              :body,
                                              :kind_of,
                                              :size,
                                              :region_id,
                                              :image,
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
