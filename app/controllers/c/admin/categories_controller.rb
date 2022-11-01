# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class CategoriesController < AdminController
      load_and_authorize_resource class: C::Category

      def index
        @categories = C::Category.hash_tree
      end

      def create
        if @category.save
          redirect_to categories_path, notice: 'Category created'
        else
          render :new
        end
      end

      def update
        if @category.update(category_params)

          if params[:category][:remove_image] && params[:category][:remove_image] === "1"
            @category.remove_image!
            @category.save!
          end

          if params[:category][:remove_image_alt] && params[:category][:remove_image_alt] === "1"
            @category.remove_image_alt!
            @category.save!
          end

          redirect_to categories_path, notice: 'Category updated'
        else
          render :edit
        end
      end

      def update_order
        children = params.require(:order)
        Category.update(children.keys, children.values)
      end

      def remove_image
        @category.remove_image = true
        @category.save!
        redirect_to [:edit, @category]
      end

      def destroy
        @category.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:categories] }
        end
      end

      def confirm_destroy; end

      # Sets up instance variables for ebay_category.js.erb that renders
      # partial for adding/reloading eBay category select fields
      # Instance variables necessary for insane logic in the _ebay_categories
      # partial
      def ebay_category
        vars = C::EbayCategory.select_setup(params, @category)
        @check = vars[:check]
        @save_name = vars[:save_name]
        @cats = vars[:cats]
        @inc = vars[:inc]
        @ebay_cat = vars[:ebay_cat]

        respond_to do |format|
          format.js do
            render 'c/admin/ebay_category'
          end
        end
      end

      private

      def category_params
        params.require(:category).permit(
          :name, :body, :image, :parent_id, :google_category_id, :weight, :template_group_id,
          :featured, :banner_url, :amazon_product_type_id, :ebay_category_id,
          :title, :meta_description, :image_alt,
          :alt_tag, :in_menu, property_key_ids: []
        )
      end
    end
  end
end
