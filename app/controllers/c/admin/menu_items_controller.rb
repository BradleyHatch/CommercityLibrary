# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class MenuItemsController < AdminController
      load_and_authorize_resource class: C::MenuItem

      def index
        @menu_items = @menu_items.hash_tree
      end

      def create
        if @menu_item.save
          redirect_to menu_items_path, notice: 'Item Created'
        else
          render :new
        end
      end

      def update
        if @menu_item.update(menu_item_params)
          redirect_to menu_items_path, notice: 'Item Updated'
        else
          render :edit
        end
      end

      def update_order
        children = params.require(:order)
        MenuItem.update(children.keys, children.values)
      end

      def destroy
        @menu_item.destroy
        respond_to do |format|
          format.js
          format.html { redirect_to [:menu_items] }
        end
      end

      def confirm_destroy; end

      private

      def menu_item_params
        params.require(:menu_item).permit(
          :name, :link, :target, :content_id, :parent_id
        )
      end
    end
  end
end
