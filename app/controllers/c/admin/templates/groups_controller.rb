# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class Templates::GroupsController < AdminController
      include C::StorefrontHelper
      load_and_authorize_resource class: C::Template::Group

      def index
      end

      def new; end

      def edit; end

      def create
        if @group.save
          redirect_to template_groups_path, notice: 'Group created'
        else
          render :new
        end
      end

      def update
        if @group.update(group_params)
          redirect_to template_groups_path, notice: 'Group updated'
        else
          render :edit
        end
      end

      def dashboard; end

      def destroy
        @group.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to template_groups_path }
        end
      end

      def sort
        @groups = C::Template::Group.all
        @groups.update_order(params[:group])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      private

      def group_params
        params.require(:template_group).permit(:id, :name, :template_page_id, :template_page_type)
      end

    end
  end
end
