# frozen_string_literal: true

task reset_all: :environment do
  Rake::Task['db:environment:set'].invoke
  Rake::Task['db:drop'].invoke
  Rake::Task['db:create'].invoke

  unless Rails.env.production?
    dir_path = Rails.root + 'db/migrate'
    if File.exist?(dir_path)
      Dir.foreach(dir_path) do |f|
        filename = File.join(dir_path, f)
        next if f == '.' || f == '..'
        File.delete(filename) if filename.ends_with? '.c.rb'
      end
    end
  end

  Rake::Task['seed'].invoke
end

task seed: :environment do
  # Rake::Task['c:install:migrations'].invoke unless Rails.env.production?
  Rake::Task['db:migrate'].invoke
  Rake::Task['seed_processes'].invoke
end

task seed_processes: :environment do
  task_list = [
    'c:install',

    'seed_content',

    'seed_brands',
    'seed_categories',
    'seed_customer_data',

    'seed_properties',

    'seed_amazon_categories',
    
    'seed_delivery_services',
    'seed_ebay_delivery_services',
    'seed_flat_delivery_services',

    'seed_products',

    'seed_ebay_wrap',
  ]

  task_list.each do |t|
    puts "\n\n"
    puts '=' * 20
    puts "Running #{t}"
    puts '=' * 20
    Rake::Task[t].invoke
  end
end
