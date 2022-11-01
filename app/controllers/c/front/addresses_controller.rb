# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Front
    class AddressesController < MainApplicationController
      def index
        @addresses = current_front_customer_account.customer.addresses
      end

      def destroy
        current_front_customer_account.customer.addresses.find(params[:id])
                                      .destroy
                                      
        redirect_to action: :index
      end

      def new
        @address = current_front_customer_account.customer.addresses.build
      end

      def create
        @address = current_front_customer_account.customer
                                                 .addresses
                                                 .build(address_params)
        if @address.valid? && @address.save
          flash[:success] = 'Address saved'
          redirect_to action: :index
        else
          render :new
        end
      end

      private

      def address_params
        params.require(:address).permit(
          :id, :customer_id, :name, :address_one, :address_two, :address_three,
          :city, :region, :country_id, :postcode, :phone, :fax, :mobile
        )
      end
    end
  end
end
