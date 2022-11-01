# frozen_string_literal: true

task seed_flat_delivery_services: :environment do
  puts 'Generating Flat Delivery Services'
  new_provider = C::Delivery::Provider.find_or_create_by!(name: 'Courier')

  new_service = new_provider.services.create!(name: 'Standard Delivery', channel: :web)

  new_service.rules.create!(base_price: 8.00, min_cart_price: 0, max_cart_price: 99.99)
  new_service.rules.create!(base_price: 0.00, min_cart_price: 100.00)
end
