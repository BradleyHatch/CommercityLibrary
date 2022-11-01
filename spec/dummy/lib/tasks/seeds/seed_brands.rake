# frozen_string_literal: true

task seed_brands: :environment do
  new_brand_count = 5 - C::Brand.count
  new_brand_count.times.each_with_index do |_brand, i|
    C::Brand.create!(
      name: Faker::Company.name,
      # remote_image_url: Faker::Company.logo
    )
  end
end
