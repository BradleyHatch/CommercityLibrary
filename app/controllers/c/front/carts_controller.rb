# frozen_string_literal: true

require_dependency 'c/front_controller'

module C
  module Front
    class CartsController < C::FrontController
      before_action :set_cart
      include C::CartsHelper

      skip_before_action :authenticate_front_customer_account!,
                         except: %i[choose_merge merge]

      def show; end

      def destroy
        @cart.cart_items.delete_all
        redirect_to carts_path
      end

      def update
        update_params = cart_params
        update_params[:cart_items_attributes].to_h.each do |k, v|
          # Rails cannot update this association automatically
          # However, we know the variant id and the option ids, so can manually
          # pick the option_variants we require
          v[:option_ids] = Array(v[:option_ids]) if v[:option_ids]
          next unless v[:option_ids]&.any?
          variant = @cart.cart_items.find(v[:id]).variant
          variant_option_ids = variant.option_variants.where(option_id: v[:option_ids]).pluck(:id)
          update_params[:cart_items_attributes][k][:option_variant_ids] = variant_option_ids
          update_params[:cart_items_attributes][k].delete(:option_ids)
        end
        if @cart.update(update_params)
          @cart.combine_duplicate_items
          redirect_to cart_path
        else
          render :show
        end
      end

      def add_voucher
        @voucher = C::Product::Voucher.where("code ILIKE ?", params[:code]).first
        if @voucher.nil?
          @voucher_error = 'Voucher code not recognised'
          flash.now[:alert] = @voucher_error
          render :show
        elsif cart.add_voucher(@voucher)
          redirect_to cart_path
        else
          @voucher_error = @voucher.has_uses_left? ? 'Voucher does not apply to current cart' : 'Voucher has no uses left'
          flash.now[:alert] = @voucher_error
          render :show
        end
      end

      def choose_merge
        @session_cart = Cart.find_by(id: session[:cart_id])
        current_customer = current_front_customer_account.customer
        @existing_cart = current_customer.cart
        case [@session_cart, @existing_cart].count(&:present?)
        when 1
          current_customer.cart ||= @session_cart
          current_customer.cart.save!
          session.delete :cart_id
        end
        redirect_to accounts_path
      end

      def toggle_gift_wrapping
        item = @cart.cart_items.find_by_id(params['id'])
        if item.present?
          item.toggle!(:gift_wrapping)
        end
      end

      def toggle_prefer_click_and_collect
        @cart.toggle!(:prefer_click_and_collect)
      end

      def merge; end

      def return_cart_items
        @cart.cart_items
      end

      private

      def set_cart
        @cart = cart
      end

      def cart_params
        params.require(:cart).permit(cart_items_attributes: [:id, :quantity, :option_ids, option_ids: []])
      end
    end
  end
end
