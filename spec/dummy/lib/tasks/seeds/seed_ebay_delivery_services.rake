# frozen_string_literal: true

task seed_ebay_delivery_services: :environment do
  providers = { 'Royal Mail' => {

    'Airmail International' => :UK_RoyalMailAirmailInternational,
    'Airsure International' =>  :UK_RoyalMailAirsureInternational,
    'First Class Recorded' => :UK_RoyalMailFirstClassRecorded,
    'First Class Standard' => :UK_RoyalMailFirstClassStandard,
    'HM Forces Mail International' => :UK_RoyalMailHMForcesMailInternational,
    'Next Day' => :UK_RoyalMailNextDay,
    'International Signed For' => :UK_RoyalMailInternationalSignedFor,
    'Second Class Recorded' => :UK_RoyalMailSecondClassRecorded,
    'Second Class Standard' => :UK_RoyalMailSecondClassStandard,
    'Special Delivery' => :UK_RoyalMailSpecialDelivery,
    'Special Delivery 9am' => :UK_RoyalMailSpecialDelivery9am,
    'Special Delivery Next Day' => :UK_RoyalMailSpecialDeliveryNextDay,
    'Surface Mail International' => :UK_RoyalMailSurfaceMailInternational,
    'Tracked' => :UK_RoyalMailTracked
  },

                'Parcel Force': {
                  '48' => :UK_Parcelforce48, 'Euro 48 International' => :UK_ParcelForceEuro48International,
                  'International Datapost' => :UK_ParcelForceInternationalDatapost, 'International Scheduled' => :UK_ParcelForceInternationalScheduled,
                  'International Economy' => :UK_ParcelForceIntlEconomy, 'International Express' => :UK_ParcelForceIntlExpress, 'International Value' => :UK_ParcelForceIntlValue,
                  'Ireland 24 International' => :UK_ParcelForceIreland24International
                },

                # "DPD": {},

                'Courier' => {
                  'Courier' => :UK_OtherCourier, '24 Hour' => :UK_OtherCourier24, '3 Days' => :UK_OtherCourier3Days, '48 Hours' => :UK_OtherCourier48,
                  '5 Days' => :UK_OtherCourier5Days, 'International' => :UK_OtherCourierOrDeliveryInternational
                },

                'Collect' => {
                  'Drop At Store' => :UK_CollectDropAtStoreDeliveryToDoor, ' In Person' => :UK_CollectInPerson, 'In Person International' => :UK_CollectInPersonInternational
                } }


  providers.each do |provider, services|
    new_provider = C::Delivery::Provider.find_or_create_by!(name: provider)
    services.each do |k, v|
      new_provider.services.find_or_create_by!(name: k, ebay_alias: v, channel: :ebay)
    end
  end
end
