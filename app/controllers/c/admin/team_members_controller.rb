# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class TeamMembersController < AdminController
      load_and_authorize_resource class: C::TeamMember

      def index
        @team_members
      end

      def new; end

      def edit; end

      def create
        if @team_member.save
          redirect_to team_members_path, notice: 'Team Member created'
        else
          render :new
        end
      end

      def update
        if @team_member.update(team_member_params)
          redirect_to team_members_path, notice: 'Team Member updated'
        else
          render :edit
        end
      end

      def dashboard; end

      def destroy
        @team_member.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to team_members_path }
        end
      end

      def sort
        @team_members = C::TeamMember.all
        @team_members.update_order(params[:team_member])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      private

      def team_member_params
        params.require(:team_member).permit(:id, :name, :role, :image, :body)
      end
    end
  end
end
