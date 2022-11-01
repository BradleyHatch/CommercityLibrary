# frozen_string_literal: true

# Generates breadcrumbs for all things

# Products: Home > [[parent of]first]Category > [first]Category > SubCategory > Product
# Category: Home > [parent]Category > Category
# Page: Home > Page

# Admin: Dashboard > <CONTROLLER NAME> > <ACTION_NAME>

module C
  module BreadcrumbsHelper
    def product_breadcrumb(product)
      arr = (cat = product.categories.first) ? cat_ancestor_link_array(cat) : []
      arr << link_to(product.name, front_end_product_path(product))
      breadcrumb(arr)
    end

    def category_breadcrumb(category)
      breadcrumb cat_ancestor_link_array(category)
    end

    def content_breadcrumb(content)
      breadcrumb [link_to(content.name, front_end_content_path(content))]
    end

    def breadcrumb(array)
      arr = [link_to('Home', '/')]
      arr << array
      content_tag(:div, safe_join(arr, ' > '), class: 'breadcrumb')
    end

    def admin_breadcrumb
      arr = [link_to('Dashboard', "/#{C.admin_mount}")]
      pa = request.path.split('/') # pa - array for the url
      arr << link_to(pa[2].titleize, "/#{pa[1..2].join('/')}") if pa.length > 2
      arr << link_to(action_name.titleize, request.path) if pa.length > 3
      content_tag(:div, safe_join(arr, ' > '), class: 'breadcrumb')
    end

    private

    def cat_ancestor_link_array(category)
      category.self_and_ancestors.reverse.map do |cat|
        link_to(cat.name, front_end_category_path(cat))
      end
    end
  end
end
