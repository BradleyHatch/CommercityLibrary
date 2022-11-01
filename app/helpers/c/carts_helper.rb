# frozen_string_literal: true

module C
  module CartsHelper
    def cart
      if front_customer_account_signed_in?
        customer = current_front_customer_account.customer
        @cart ||= C::Cart.where(customer_id: customer.id).order(created_at: :desc).first || customer.build_cart
      else
        @cart ||= (C::Cart.find_by(id: session[:cart_id]) || C::Cart.new)
      end
    end

    def store_cart
      if front_customer_account_signed_in?
        current_front_customer_account.customer.store_cart cart
      else
        session[:cart_id] = cart.id
      end
    end

    def link_to_add_to_cart(text, variant, _opts={}, &block)
      form_tag c.cart_cart_items_path do
        form_elements = [hidden_field_tag('cart_item[variant_id]', variant.id)]
        if variant.master.add_ons.any?
          form_elements << raw('<h5 class="add-on-title">Recommended with your purchase</h5>')
          variant.master.add_ons.each_with_index do |add_on, index|
            form_elements << content_tag(:div, class: 'add-on') do
              label_tag("add_on_product_ids[#{index}]") do
                check_box_tag("add_on_product_ids[#{index}]", add_on.id) +
                  "#{add_on.name} (#{humanized_money_with_symbol(add_on.price(channel: :web))})"
              end
            end
          end
        end
        if variant.option_variants.any?
          form_elements << raw('<h5 class="add-on-title">Purchase Options</h5>')
          if C.can_select_many_product_options
            variant.options.each do |option|
              form_elements << content_tag(:div, class: 'add-on') do
                label_tag do
                  check_box_tag('cart_item[option_ids][]', option.id) +
                    "#{option.name} (#{humanized_money_with_symbol(option.price.with_tax)})"
                end
              end
            end
          else
            form_elements << select_tag('cart_item[option_ids][]', options_for_select(variant.options.collect{ |x| [x.name, x.id] }))
          end
        end

        product_category_ids = variant.categories.pluck(:id)
        C::Product::Dropdown.where(active: true).each_with_index do |dropdown, i|
          next if (product_category_ids & dropdown.categories.pluck(:id)).empty? && (dropdown.variant_ids & [variant.master.main_variant.id]).empty?
          options = options_for_select(dropdown.dropdown_options.order(name: :asc).pluck(:name, :value))
          name = "product_dropdown[#{dropdown.name}]"
          form_elements << select_tag(name, options, {class: "product_dropdown_selector", name: name, prompt: "-- Please select #{dropdown.name} --"})
          unless i.zero?
            form_elements << content_tag(:br)
          end
        end

        form_elements << link_to('Buy Now', 'javascript:void(0)', class: 'submit_cart_button submit_cart_button--bypass', id: 'add_to_cart_btn--bypass', data: { 'bypass-cart' => true } ) if C.bypass_cart_link
        form_elements << number_field_tag('cart_item[quantity]', 1) if C.add_to_cart_quantity

        if block_given?
          form_elements <<  link_to('javascript:void(0)', { class: 'submit_cart_button', id: 'add_to_cart_btn' }, &block)
        else
          form_elements << link_to(text, 'javascript:void(0)', class: 'submit_cart_button', id: 'add_to_cart_btn')
        end

        safe_join(form_elements)
      end
    end

    def remove_from_cart(text, cart_item)
      link_to text, c.cart_item_path(cart_item), method: :delete
    end

    def cart_quantity_form(cart_item)
      form_for cart_item, url: c.url_for(cart_item) do |f|
        f.label(:quantity) +
          f.select(:quantity, (1..25)) +
          f.submit
      end
    end

    def add_cart_item_form(product)
      cart_item = C::CartItem.new
      form_for cart_item, url: c.url_for(cart_item) do |f|
        f.hidden_field(:product_id, value: product.id) +
          f.label(:quantity) +
          f.select(:quantity, (1..25)) +
          f.submit
      end
    end
  end
end
