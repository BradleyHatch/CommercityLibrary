# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class SettingGroupsController < AdminController
      load_and_authorize_resource class: C::SettingGroup

      def show; end
    end
  end
end
