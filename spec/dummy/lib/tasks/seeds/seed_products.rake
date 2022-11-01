# frozen_string_literal: true

task seed_products: :environment do
  C::Product::Option.create!(name: 'Warranty', price: C::Price.create(without_tax_pennies: rand(100 - 1000)))
  C::Product::Option.create!(name: 'Go-Faster Stripes', price: C::Price.create(without_tax_pennies: rand(100 - 1000)))
  C::Product::Option.create!(name: 'Gold-Plated Switches', price: C::Price.create(without_tax_pennies: rand(100 - 1000)))
  C::Product::Option.create!(name: "#{Faker::Hipster.word.titleize} Insurance", price: C::Price.create(without_tax_pennies: rand(100 - 1000)))
  C::Product::Option.create!(name: 'Spare Ammunition', price: C::Price.create(without_tax_pennies: rand(100 - 1000)))
  C::Product::Option.create!(name: 'Edible Glitter', price: C::Price.create(without_tax_pennies: rand(100 - 1000)))

  seed_count = 12
  seed_count.times do |i|
    master = C::Product::Master.create!(
      brand: C::Brand.order('RANDOM()').first,
      web_channel_attributes: {
        description: Faker::Lorem.paragraph(2),
        features: Faker::Lorem.paragraph(2)
      },
      main_variant_attributes: {
        sku: Faker::Code.ean,
        name: Faker::Book.title,
        mpn: Faker::Code.isbn,
        published_web: true,
        rrp: rand(1..10),
        current_stock: rand(1..10),
        web_price_attributes: {
          with_tax: Faker::Number.decimal(2)
        }
      }
    )

    C::Product::Option.order("RANDOM()").limit(rand(0..3)).each do |option|
      option_variant = master.main_variant.option_variants.create!(option: option)
    end

    master.categorizations.create!(category: C::Category.order('RANDOM()').first)

    master.main_variant.update(status: :active)
  end
end
