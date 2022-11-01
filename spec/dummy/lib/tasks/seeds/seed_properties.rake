# frozen_string_literal: true

task seed_properties: :environment do
  # Fix issue where slug was not considered a Variant column, along with
  # something to do with eBay channels' description
  C::Product::Variant.reset_column_information
  C::Product::Channel::Ebay.reset_column_information

  # Clear everything we could have created previously
  C::Product::Master.all.each(&:destroy)
  C::Product::PropertyKey.delete_all

  cat = C::Category.find_or_create_by!(name: 'stuff', body: 'stuff stuff')
  seed_count = 15
  seed_count.times do |i|
    puts "#{i + 1}/#{seed_count} Products"
    master = C::Product::Master.new(brand: C::Brand.second)
    master.build_main_variant(
      sku: Faker::Code.ean,
      name: Faker::Hipster.words(2).join(' ').titlecase,
      published_amazon: true,
      published_ebay: true, published_web: false,
      weight: rand(0..20),
      cost_price: rand(50..100).to_s,
      retail_price: C::Price.create!(with_tax: (rand * 50) + 50, tax_rate: 20.0),
      featured: rand(2) == 0,
      status: rand(0..1)
    )
    master.save!

    master.main_variant.barcodes.create!(value: Faker::Code.ean, symbology: :EAN)
    key = C::Product::PropertyKey.find_or_create_by!(key: 'Color')
    master.main_variant.property_values.create!(property_key: key, value: 'red')

    master.create_web_channel!(name: '', description: '')
    master.save!

    master.categorise cat
  end
end
