# frozen_string_literal: true

require_dependency 'c/front_controller'

module C
  module Front
    class CartItemsController < C::FrontController
      include C::CartsHelper

      skip_before_action :authenticate_front_customer_account!
      before_action :set_cart_item, only: %i[update destroy]

      def create
        variants = []

        if cart_item_params[:variants].present?
          variants = cart_item_params[:variants]
        else
          variants = [cart_item_params]
        end

        variants.each do |variant|
          item = { variant_id: variant[:variant_id] }
          quantity =  variant[:quantity] || 1
          option_ids = variant[:option_ids] || []
          
          cart.add_item(item, quantity, option_ids)

          cart_item = cart.cart_items.last
  
          if cart_item.variant_id
            cart_item.cart_item_notes.destroy_all
            if params[:product_dropdown]
              params[:product_dropdown].each do |k, v|
                next if v.blank? || k.blank?
                cart_item.cart_item_notes.create!(name: k, value: v)
              end
            end
          end  
        end
      
        params[:add_on_product_ids]&.each do |_index, id|
          next unless item = C::Product::Master.find_by(id: id.to_i)
          cart.add_item(variant_id: item.main_variant.id)
        end

        store_cart

        params['bypass_cart'] ? redirect_to(new_checkout_path) : redirect_to(cart_path)
      end

      def update
        @cart_item.update(cart_item_params(:cart_item))
        redirect_to c.cart_path
      end

      def destroy
        if @cart_item.voucher
          @cart_item.voucher.update(times_used: @cart_item.voucher.times_used - 1)
        end
        
        @cart_item.destroy

        redirect_to c.cart_path
      end

      private

      def set_cart_item
        @cart_item = cart.cart_items.find(params[:id])
      end

      def cart_item_params
        params.require(:cart_item).permit(:variant_id, :quantity, option_ids: [], variants: [:variant_id, :quantity, option_ids: []])
      end
    end
  end
end
