# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Front
    class WishlistItemsController < MainApplicationController

      def index
        if front_customer_account_signed_in?
          customer = current_front_customer_account.customer
          create_wishlist_item(customer, params[:product_id]) if params[:product_id]
          @wishlist = customer.wishlist
        else
          redirect_to new_front_customer_account_session_path
        end
      end

      def destroy
        if front_customer_account_signed_in? && params[:id]
          customer = current_front_customer_account.customer
          customer.wishlist_items.find(params[:id]).destroy!
          redirect_to front_wishlist_index_path
        end
      end

      def create_wishlist_item(customer, id)
        customer.wishlist_items.create!(variant_id: id) unless customer.wishlist.pluck(:variant_id).include? id.to_i
        redirect_to front_wishlist_index_path
      end

      private

      def wishlist_item_params
        params.require(:wishlist_item).permit(:id, :customer_id, :variant_id)
      end

    end
  end
end
