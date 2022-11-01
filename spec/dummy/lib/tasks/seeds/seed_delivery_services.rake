# frozen_string_literal: true

task seed_delivery_services: :environment do
  C::Delivery::Provider.find_each(&:destroy)

  providers = {
    'Courier' => {
      'Standard Delivery' => [
        {
          price: 8,
          max: 99.99 * 100
        },
        {
          price: 0,
          min: 100 * 100
        }
      ]
    },
    'In store' => {
      '1 Hour Collection' => [
        {
          price: 0
        }
      ]
    }
  }

  providers.each do |provider, services|
    dsp = C::Delivery::Provider.create!(name: provider)

    services.each do |service, prices|
      ds = dsp.services.create!(
        name: service,
        channel: :web
      )

      prices.each do |price|
        ds.rules.create!(
          base_price: price[:price],
          min_cart_price_pennies: price[:min] || 0,
          max_cart_price_pennies: price[:max]
        )
      end
    end
  end
end
