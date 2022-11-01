# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class BrandsController < MainApplicationController
      def show
        @brand = C::Brand.from_url(params[:id])
        @content = @cbrand
        assign_page_info @brand.page_info
        @products = @brand.variants
                          .for_display
                          .order(C.default_products_sort)
                          .paginate(page: params[:page],
                                    per_page: (params[:per_page] || 12))
      end
    end
  end
end
