# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class CollectionsController < MainApplicationController
      include C::StorefrontHelper

      def show
        @collection = C::Collection.from_url(params[:id])
        @content = @collection
        assign_page_info @collection.page_info

        @products = @collection.variants.published.for_display

        @products = @products.in_stock if C.hide_zero_stock_products

        @products = @products.featured_first.paginate(page: ((params[:page]&.gsub(/[^\d,\.]/, '')).to_i > 0 ? params[:page] : 1), per_page: (params[:per_page] || C.products_per_category_page))
      end
    end
  end
end
