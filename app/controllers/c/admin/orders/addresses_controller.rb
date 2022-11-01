# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Orders
      class AddressesController < AdminController
        load_resource :customer, class: C::Customer
        load_resource :sale, class: C::Order::Sale
        skip_authorization_check

        before_action :set_parent_resource
        before_action :set_address, only: %i[edit update destroy]
        before_action :build_address_object, only: %i[new create]

        def create
          if @address.save
            @order&.update("#{@address_type}_address_id" => @address.id)
            flash[:notice] = 'Address Saved'
            redirect_to @parent_resource
          else
            render :new
          end
        end

        def update
          if @address.update(address_params)
            flash[:notice] = 'Address Saved'
            redirect_to @parent_resource
          else
            render :edit
          end
        end

        def destroy
          @address.destroy
          respond_to do |format|
            format.js
            format.html { redirect_to @parent_resource }
          end
        end

        private

        def set_address
          @address = C::Address.find(params[:id])
        end

        def set_parent_resource
          @parent_resource = @customer || @sale
        end

        def build_address_object
          if (@order = @sale)
            if params[:address][:address_type] == 'shipping'
              @address = if action_name == 'create'
                           @order.build_shipping_address(address_params)
                         else
                           @order.build_shipping_address
                         end
              @address_type = 'shipping'
            else
              @address = if action_name == 'create'
                           @order.build_billing_address(address_params)
                         else
                           @order.build_billing_address
                         end
              @address_type = 'billing'
            end
          else
            @address = if action_name == 'create'
                         @parent_resource.addresses.build(address_params)
                       else
                         @parent_resource.addresses.build
                       end
          end
        end

        def address_params
          params.require(:address).permit(:name, :address_one, :address_two,
                                          :address_three, :city, :region,
                                          :postcode, :country_id, :phone, :fax,
                                          :mobile, :address_type)
        end
      end
    end
  end
end
