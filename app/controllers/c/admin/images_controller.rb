# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class ImagesController < AdminController
      load_and_authorize_resource class: C::Image

      def create
        # Take upload from params[:file] and store it somehow...
        # Optionally also accept params[:hint] and consume if needed
        image = C::Image.create!(image: params[:file])

        render json: {
          image: {
            url: image.image.url
          }
        }, content_type: 'text/html'
      end
    end
  end
end
