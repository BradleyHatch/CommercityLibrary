# frozen_string_literal: true

module C
  class AddressPresenter < BasePresenter
    presents :address

    def line
      address_parts = address.full_address_array
      truncate(safe_join(address_parts, ', '), length: 100)
    end

    def block
      names = %w[name address_one address_two address_three city region postcode country_name]
      address_parts = []
      names.each do |method|
        part = address.send(method)
        next if part.blank?
        address_parts.append(
          content_tag(:div, part, class: ['address__part', "address__#{method}"])
        )
      end
      content_tag :div, safe_join(address_parts), class: 'address'
    end
  end
end
