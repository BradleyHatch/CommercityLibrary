# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class Templates::RegionsController < AdminController
      include C::StorefrontHelper
      before_action :set_parent
      load_and_authorize_resource class: C::Template::Region

      def index
      end

      def new
      end

      def edit
      end

      def create
        @region = @group.regions.new(region_params)
        if @region.save
          redirect_to edit_template_group_template_region_path(@group.id, @region.id), notice: 'Region created'
        else
          render :new
        end
      end

      def update
        if @region.update(region_params)
          redirect_to edit_template_group_template_region_path(@group.id, @region.id), notice: 'Region updated'
        else
          render :edit
        end
      end

      def set_parent
        @group = C::Template::Group.find(params[:group_id])
      end

      def destroy
        @region.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to edit_template_group_path(@group) }
        end
      end

      def sort
        @regions = @group.regions
        @regions.update_order(params[:group])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      private

      def region_params
        params.require(:template_region).permit(:id, :name, :group_id)
      end

    end
  end
end
