# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class CountriesController < AdminController
      load_and_authorize_resource class: C::Country

      def index
        @countries = @countries.ordered.includes(:zone)
      end

      def edit
        @zones = C::Zone.all.pluck(:name, :id)
      end

      def update
        if @country.update(country_params)
          redirect_to countries_path
        else
          edit
        end
      end

      def toggle_state
        @country.update(active: !@country.active?)
        respond_to do |format|
          format.html { redirect_to [:countries] }
          format.js
        end
      end

      def country_params
        params.require(:country).permit(:id, :zone_id)
      end
    end
  end
end
