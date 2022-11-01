# frozen_string_literal: true

task seed_amazon_categories: :environment do
  C::AmazonImportJob.new.seed_db_with_cats(%w[MusicalInstruments Books])
end
