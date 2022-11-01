# frozen_string_literal: true

namespace :c do
  namespace :slugs do
    task update_to_sku: :environment do

      C::Product::Variant.all.each do |variant|

        variant.update(slug: variant.sku.parameterize)

      end

    end

  end
end