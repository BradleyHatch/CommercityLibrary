# frozen_string_literal: true

namespace :c do
  task check_price_matches: :environment do
    compare_prices = C::ComparePrices.new
    variants = C::Product::Variant.joins(:price_matches).group('c_product_variants.id')
    variants.each do |variant|
      compare_prices.perform(variant.id)
    end
  end
end
