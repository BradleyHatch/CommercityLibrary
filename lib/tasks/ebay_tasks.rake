# frozen_string_literal: true

namespace :c do
  namespace :ebay do

    ########################
    ########################
    ########################

    task check_status: :environment do
      if (ENV['USE_EBAY_PRODUCT_PIPELINE'])
        C::EbayPipeline.status_all
      end
    end

    ########################
    ########################
    ########################

    task deploy: :environment do
      Rake::Task['c:ebay:seed_delivery_services'].invoke
      Rake::Task['c:ebay:import_categories'].invoke
    end

    task get_orders: :environment do
      C::EbayJob.perform_now('import_ebay_orders')
    end

    task import_categories: :environment do
      puts 'Importing categories from eBay...'
      C::EbayJob.perform_now('categories_import')
    end

    task mass_stock_update: :environment do
      C::EbayJob.perform_now('mass_stock_update')
    end

    task get_offers: :environment do
      C::EbayJob.perform_now('get_offers')
    end

    task get_messages: :environment do
      C::EbayJob.perform_now('get_messages')
    end

    task get_questions: :environment do
      C::EbayJob.perform_now('get_questions')
    end

    task pull_messages: :environment do
      C::EbayJob.perform_now('pull_messages')
    end

    task pull_questions: :environment do
      C::EbayJob.perform_now('pull_questions')
    end

    task build_and_sync_ebay_listings: :environment do
      C::EbayJob.perform_now('build_and_sync_job')
    end

    task checked_for_ended_listings: :environment do
      C::BackgroundJob.process('Ebay: Check For Ended Listings') do
        C::EbayJob.perform_now('inactive_unsold_listings')
      end
    end

    task seed_delivery_services: :environment do
      puts 'Generating Ebay Delivery Services'
      PROVIDERS.each do |provider, services|
        puts "\tMaking #{provider}"
        new_provider = C::Delivery::Provider.find_or_create_by!(name: provider)
        services.each do |k, v|
          puts "\t\tMaking #{v}"
          new_provider.services.find_or_create_by!(name: k, ebay_alias: v, channel: :ebay)
        end
      end
    end
  end
end

PROVIDERS ||= {
  'Royal Mail': {
    'Airmail International': :UK_RoyalMailAirmailInternational,
    'Airsure International':  :UK_RoyalMailAirsureInternational,
    'First Class Recorded': :UK_RoyalMailFirstClassRecorded,
    'First Class Standard': :UK_RoyalMailFirstClassStandard,
    'HM Forces Mail International': :UK_RoyalMailHMForcesMailInternational,
    'Next Day': :UK_RoyalMailNextDay,
    'International Signed For': :UK_RoyalMailInternationalSignedFor,
    'Second Class Recorded': :UK_RoyalMailSecondClassRecorded,
    'Second Class Standard': :UK_RoyalMailSecondClassStandard,
    'Special Delivery': :UK_RoyalMailSpecialDelivery,
    'Special Delivery 9am': :UK_RoyalMailSpecialDelivery9am,
    'Special Delivery Next Day': :UK_RoyalMailSpecialDeliveryNextDay,
    'Surface Mail International': :UK_RoyalMailSurfaceMailInternational,
    'Tracked': :UK_RoyalMailTracked
  },
  'Parcel Force': {
    '48': :UK_Parcelforce48,
    'Euro 48 International': :UK_ParcelForceEuro48International,
    'International Datapost': :UK_ParcelForceInternationalDatapost,
    'International Scheduled': :UK_ParcelForceInternationalScheduled,
    'International Economy': :UK_ParcelForceIntlEconomy,
    'International Express': :UK_ParcelForceIntlExpress,
    'International Value': :UK_ParcelForceIntlValue,
    'Ireland 24 International': :UK_ParcelForceIreland24International
  },
  'Courier': {
    'Courier': :UK_OtherCourier,
    '24 Hour': :UK_OtherCourier24,
    '3 Days': :UK_OtherCourier3Days,
    '48 Hours': :UK_OtherCourier48,
    '5 Days': :UK_OtherCourier5Days,
    'International': :UK_OtherCourierOrDeliveryInternational
  },
  'Collect': {
    'Drop At Store': :UK_CollectDropAtStoreDeliveryToDoor,
    'In Person': :UK_CollectInPerson,
    'In Person International': :UK_CollectInPersonInternational
  }
}.freeze
