# frozen_string_literal: true

namespace :c do
  task install: [:environment] do
    C::User.find_or_create_by(email: 'admin@example.com') do |user|
      user.name = 'Admin'
      user.password = 'example_admin_password'
      user.cd2admin = true
    end
    Rake::Task['c:settings'].invoke
    Rake::Task['c:import_countries'].invoke
  end

  task settings: [:environment] do
    C::SettingGroup.find_or_create_by!(name: 'Store', body: 'These settings are for your store.')
    C::SettingGroup.find_or_create_by!(name: 'Sync', body: 'These setting control syncing with external services.')
    C::Setting.new_setting(:amazon_sync, false, group: :sync, type: :boolean) unless C::Setting.exists?(key: :amazon_sync)
    C::Setting.new_setting(:ebay_sync, false, group: :sync, type: :boolean) unless C::Setting.exists?(key: :ebay_sync)
  end

  task import_countries: :environment do
    eu_members = ['United Kingdom']
    countries = File.read(C::Engine.root + 'db/seed_data/countries.txt').tr("\r", "\n").split("\n").map { |c| c.split(/\t/) }
    puts 'Generating Countries'
    # Not sure whether group actually is a group or not, but it does include
    # the EU. We don't use it anyway.
    countries.each do |iso2, iso3, name, _group, tld, currency, _zone, numeric|
      country = C::Country.find_or_initialize_by(iso2: iso2)
      country.assign_attributes(
        name: name,
        iso3: iso3,
        tld: tld.delete('.'),
        currency: currency,
        eu: eu_members.map(&:upcase).include?(name.upcase),
        numeric: numeric
      )
      country.save!
      print '#'
    end
    # Add newline to show end of task.
    puts
  end

  task update_eu_countries_for_tax: :environment do
    puts 'Update EU Countries for tax'

    C::Country.where.not(iso2: 'GB').update_all(eu: false)

    # Add newline to show end of task.
    puts
  end

  task google_categories: :environment do
    google_categories = File.read(C::Engine.root + 'db/seed_data/google_categories.txt').tr("\r", "\n").split("\n").map { |c| c.split(/\t/) }
    puts 'Building Google Categories'

    google_categories.each_with_index do |str, i|
      next if i.zero?
      id, full_path = str[0].scan(/(\d+) - (.*)/).flatten
      split_path = full_path.split(' > ')
      name = split_path.pop

      cat = C::GoogleCategory.find_or_create_by(name: name, category_id: id, full_path: full_path)
      cat.update(category_parent_name: split_path.pop) if split_path.any?

      print '#'
    end
    # Add newline to show end of task.
    puts 'generating hierarchy (THIS TAKES A WHILE);...'
    C::GoogleCategory.create_hierarchy
    puts
  end

  task create_permission_subjects: :environment do
    C::PermissionSubject.create(name: 'User', subject_type: 'C::User')
    C::PermissionSubject.create(name: 'Category', subject_type: 'C::Category')
    C::PermissionSubject.create(name: 'Roles', subject_type: 'C::Role')
    C::PermissionSubject.create(name: 'Countries', subject_type: 'C::Countries')
    C::PermissionSubject.create(name: 'Settings', subject_type: 'C::Setting')
  end

  task create_admin_role: %i[environment create_permission_subjects] do
    role = C::Role.create(name: 'Admin', body: 'Main administrator of the store')
    role.build_or_find_permissions
    role.permissions.each do |permission|
      permission.read = true
      permission.new = true
      permission.edit = true
      permission.remove = true
    end
    role.save!
  end

  task commercity_engine: :environment do
    Rake::Task['c:update_cache'].invoke
    Rake::Task['c:import_scheduled_csv'].invoke
    Rake::Task['c:background_jobs:set_status'].invoke
  end

  task convert_variant_dimensions_to_many: :environment do
    C::Product::Variant.all.each do |variant|
      next if variant.variant_dimensions.any?
      puts variant.sku
      variant.variant_dimensions.create(
        weight: variant["weight"],
        x_dimension: variant.x_dimension,
        y_dimension: variant.y_dimension,
        z_dimension: variant.z_dimension,
        dimension_unit: variant.dimension_unit,
      )
    end
  end
end
