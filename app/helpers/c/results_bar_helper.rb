# frozen_string_literal: true

module C
  module ResultsBarHelper
    def results_range(products)
      displayed_amount = (params[:per_page] || C.products_per_category_page).to_i
      page_number = (params[:page] || 1).to_i
      range_start =  displayed_amount * page_number - displayed_amount + 1
      range_end = if (displayed_amount * page_number) > products.count
                    products.count
                  else
                    (displayed_amount * page_number)
                  end
      "#{range_start} - #{range_end}"
    end

    def per_page_links(page_array)
      links = []
      page_array.each do |per_page|
        per_page = per_page.to_s
        links << link_to(per_page,
                         url_for(
                           per_page: per_page,
                           page: 1,
                           f_search: (params[:f_search] if params[:f_search])
                         ),
                         class: ('selected' if params[:per_page] == per_page))
      end
      safe_join(links)
    end

    def filter_select_tag(search_object)
      select_tag :sort_products,
                 options_for_select(
                   [
                     ['Newly added', sort_url(search_object, 'id desc')],
                     ['Price High to Low', sort_url(search_object, 'cache_web_price_pennies desc')],
                     ['Price Low to High', sort_url(search_object, 'cache_web_price_pennies asc')],
                     ['In Stock', sort_url(search_object, 'current_stock desc')]
                   ],
                   "#{request.path}?#{request.query_string}"
                 ), id: 'dynamic_select'
    end
  end
end
