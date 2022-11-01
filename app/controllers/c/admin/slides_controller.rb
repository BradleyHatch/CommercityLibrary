# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class SlidesController < AdminController
      load_and_authorize_resource :slideshow, class: C::Slideshow
      load_and_authorize_resource :slide, class: C::Slide, through: :slideshow

      def create
        @slide = @slideshow.slides.new(slide_params)
        if @slide.save
          redirect_to edit_slideshow_path(@slideshow), notice: 'Slide created'
        else
          render :new
        end
      end

      def update
        if @slide.update(slide_params)
          redirect_to edit_slideshow_path(@slideshow), notice: 'Slide updated'
        else
          render :edit
        end
      end

      def destroy
        @slide.destroy
        respond_to do |format|
          format.js
          format.html do
            redirect_to edit_slideshow_path(@slideshow), notice: 'Slide deleted'
          end
        end
      end

      def sort
        @slides = C::Slideshow.find(params[:slideshow_id]).slides
        @slides.update_order(params[:slideshow])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      private

      def slide_params
        params.require(:slide).permit(:name, :body, :url, :image)
      end
    end
  end
end
