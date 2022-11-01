# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class VouchersController < AdminController
        load_and_authorize_resource class: C::Product::Voucher, only: %i[
          index new edit create update destroy confirm_destroy
        ]

        def index
          @vouchers = @vouchers.ordered
        end

        def new; end

        def edit
          set_orders_index_values
        end

        def create
          @voucher = C::Product::Voucher.new(voucher_params)
          if @voucher.save
            redirect_to C::Product::Voucher
          else
            render :new
          end
        end

        def update
          if @voucher.update(voucher_params)
            redirect_to C::Product::Voucher
          else
            render :edit
            set_orders_index_values
          end
        end

        def destroy
          @voucher.destroy
          redirect_to C::Product::Voucher
        end

        private

        def set_orders_index_values
          @q = if params[:q]
            @voucher.orders.ordered.ransack(params[:q])
          else
            @voucher.orders.ordered.ransack(params[:q])
          end
          @orders = C::Order::Sale.where(id: @q.result.pluck(:id).uniq).ordered.paginate(page: params[:page], per_page: 99)
        end

        def voucher_params
          params.require(:product_voucher).permit(
            :name, :code, :restricted, :restricted_brand, :restricted_category, :discount_multiplier,
            :flat_discount, :per_item_discount, :per_item_discount_multiplier,
            :minimum_cart_value, :start_time, :end_time, :active, :uses,
            variant_vouchers_attributes: %i[id variant_id _destroy],
            brand_vouchers_attributes: %i[id brand_id _destroy],
            category_vouchers_attributes: %i[id category_id _destroy],
          )
        end
      end
    end
  end
end
