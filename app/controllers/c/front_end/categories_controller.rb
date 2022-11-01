# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class CategoriesController < MainApplicationController
      include C::StorefrontHelper

      def show
        @category = C::Category.from_url(params[:id])
        @content = @category
        assign_page_info @category.page_info

        @products = @category.self_and_descendant_product_variants.published.for_display
        @products = @products.in_stock if C.hide_zero_stock_products

        @products = @products.in_stock if params[:q][:s] == 'current_stock desc' rescue nil
        @q = @products.ransack(params[:q])

        if @q.sorts.empty?
          if C.default_category_products_sort.present?
            @q.sorts = Array.wrap(C.default_category_products_sort)
          else
            @q.sorts = Array.wrap(C.default_products_sort)
          end
        end

        @products = @q.result

        # thing for brand filtering
        @products = @products.where(master_id: C::Product::Master.where(brand_id: params[:brand_filter].to_i)) if params[:brand_filter]

        # weird code for filtering products
        filter_syms = C::Product::PropertyKey.all.pluck(:key).map { |k| k.parameterize.to_sym }
        @prod_ids = get_product_ids_from_params(filter_syms) & @products.ids

        @prod_ids = @products.ids if @prod_ids.blank?

        @products = @products.where(id: @prod_ids).featured_first.paginate(page: ((params[:page]&.gsub(/[^\d,\.]/, '')).to_i > 0 ? params[:page] : 1), per_page: (params[:per_page] || C.products_per_category_page))

        keys = C::Product::PropertyKey
                .where(display: true)
                .joins(property_values: [:variant])
                .group(:id)
                .where(c_product_property_values: { variant_id: @prod_ids })
                .having('COUNT(c_product_property_values.id) > 0')
                .order(weight: :desc)

        @arr = keys.map { |k| [k.key, k, k.key.parameterize.to_sym] }

      end
    end
  end
end
