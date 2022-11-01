# frozen_string_literal: true

module C
  module WishlistHelper

    def add_to_wishlist(product, klass=nil, text='Add to Wishlist')
      link_to text, front_wishlist_index_path(product_id: product.id), class: klass
    end

    def remove_from_wishlist(item, klass=nil, text='Remove from Wishlist')
      link_to text, front_wishlist_path(item), method: :delete, class: klass
    end

    def wishlist_url(klass=nil, text='Wishlist')
      link_to "#{text}(#{wishlist_count})", front_wishlist_index_path, class: klass
    end

    def wishlist_count
      if front_customer_account_signed_in?
        customer = current_front_customer_account.customer
        wishlist_count = customer.wishlist.count
      else
        0
      end
    end

    def wishlist_continue_shopping_link_to
      return '/' unless front_customer_account_signed_in?
      customer = current_front_customer_account.customer
      if customer.wishlist.any? && (category = customer.wishlist.first.variant.categories.first)
        front_end_category_path(category)
      else
        '/'
      end
    end

  end
end
