# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class ProductReservationsController < AdminController
      load_and_authorize_resource class: C::ProductReservation

      def index
        @product_reservations = filter_and_paginate(@product_reservations,
                                                    'created_at desc')
      end

      def destroy
        @product_reservation.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to product_reservations_path }
        end
      end

      private

      def reservation_params
        params.require(:product_reservation).permit(:id, :name, :email,
                                                    :product_variant_id)
      end
    end
  end
end
