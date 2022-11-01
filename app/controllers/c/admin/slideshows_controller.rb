# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class SlideshowsController < AdminController
      load_and_authorize_resource class: C::Slideshow

      def index
        @slideshows = @slideshows.ordered
      end

      def create
        if @slideshow.save
          redirect_to [:edit, @slideshow], notice: 'Slideshow created'
        else
          render :new
        end
      end

      def update
        if @slideshow.update(slideshow_params)
          redirect_to [:edit, @slideshow], notice: 'Slideshow updated'
        else
          render :new
        end
      end

      private

      def slideshow_params
        params.require(:slideshow).permit(:id, :name, :body)
      end
    end
  end
end
