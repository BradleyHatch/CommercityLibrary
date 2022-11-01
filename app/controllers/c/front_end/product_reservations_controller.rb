# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class ProductReservationsController < MainApplicationController
      def new
        @reservation = C::ProductReservation.new
        @reservation.product_variant_id = params[:product_id]
      end

      def create
        @product = C::Product::Variant.find(params[:product_reservation][:product_variant_id])
        @reservation = C::ProductReservation.new(reservation_params)
        if recaptcha && @reservation.save
          C::EnquiriesMailer.customer_reservation_email(@reservation).deliver_now
          C::EnquiriesMailer.store_reservation_email(@reservation).deliver_now
          redirect_to confirmation_front_end_product_reservation_path(@reservation)
        else
          render :new
        end
      end

      def confirmation
        @reservation = C::ProductReservation.find(params[:id])
      end

      private

      def recaptcha
        return true unless C.recaptcha
        verify_recaptcha(model: @reservation)
      end

      def reservation_params
        params.require(:product_reservation)
              .permit(:name, :email, :phone, :product_variant_id)
      end
    end
  end
end
