# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class RolesController < AdminController
      load_and_authorize_resource class: C::Role

      def index; end

      def new; end

      def create
        if @role.save
          flash[:success] = 'Role saved.'
          redirect_to roles_path
        else
          render :new
        end
      end

      def edit; end

      def update
        if @role.update(role_params)
          flash[:success] = 'Role updated.'
          redirect_to roles_path
        else
          render :edit
        end
      end

      def destroy
        if @role.destroy
          flash[:success] = 'Role deleted.'
        else
          flash[:error] = 'An error occurred.'
        end
        redirect_to roles_path
      end

      def confirm_destroy; end

      private

      def role_params
        params.require(:role).permit(
          :name, :body,
          permissions_attributes: %i[id permission_subject_id
                                     read new edit remove]
        )
      end
    end
  end
end
