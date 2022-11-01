# frozen_string_literal: true

task seed_customer_data: :environment do
  5.times do |i|
    customer = C::Customer.create!(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      company: (rand(4) > 2 ? Faker::Company.name : nil),
      phone: "0#{rand(1000..9999)} #{rand(100_000..999_999)}",
      mobile: "0#{rand(7000..9999)} #{rand(100_000..999_999)}",
      channel: rand(0..2)
    )
    customer.addresses.create!(
      name: customer.name,
      address_one: Faker::Address.street_name,
      city: Faker::Address.city,
      region: 'Norfolk',
      postcode: Faker::Address.postcode,
      country_id: 77,
      phone: customer.phone,
      default: true
    )
    customer.create_account!(
      email: customer.email,
      password: 'password'
    )

    customer.save!
  end
end
