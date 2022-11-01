# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    module Orders
      class ItemsController < AdminController
        before_action :set_order
        load_and_authorize_resource :item, class: C::Order::Item

        def create
          @item = @order.items.build(item_params)

          if (existing_item = @order.items.find_by(
            product_id: @item.product_id,
            name: @item.name,
            price_pennies: @item.price_pennies
          )
             )
            existing_item.update(quantity: (existing_item.quantity + 1))
          elsif @item.save
            redirect_to order_sale_path(@order)
          else
            render :new
          end
        end

        def destroy
          @item.destroy
          redirect_to @order
        end

        def update
          if @item.update(item_params)
            redirect_to order_sale_path(@order)
          else
            render :new
          end
        end

        private

        def set_order
          @order = C::Order::Sale.find(params[:sale_id])
        end

        def item_params
          params.require(:order_item).permit(
            :product_id, :quantity, :name, :sku, :tax_rate, :price
          )
        end
      end
    end
  end
end
