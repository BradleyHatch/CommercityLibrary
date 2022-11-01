# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class SettingsController < AdminController
      load_and_authorize_resource class: C::Setting
      before_action :set_group

      def update
        if @setting.data.update(setting_params)
          redirect_to @group, notice: 'Setting updated'
        else
          render :edit
        end
      end

      def destroy
        @setting.update value: nil
        redirect_to @group, notice: 'Setting updated'
      end

      private

      def set_group
        @group = @setting.group
      end

      def setting_params
        params.require(:setting).permit(:value)
      end
    end
  end
end
