# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class ImagesController < AdminController
        skip_authorization_check

        def sort
          @images = C::Product::Variant.find(params[:product_variant_id]).images
          @images.update_order(params[:variant_image])
          respond_to do |format|
            format.js { head :ok, content_type: 'text/html' }
          end
        end
      end
    end
  end
end
