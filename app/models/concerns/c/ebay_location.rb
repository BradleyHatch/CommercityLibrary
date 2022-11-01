# frozen_string_literal: true

module C
  module EbayLocation
    extend ActiveSupport::Concern

    included do
      enum location: [
        'Europe',
        'European Union',
        'Ireland',
        'Germany',
        'France',
        'Greece',
        'Italy',
        'Spain',
        'Russian Federation',
        'N. and S. America',
        'United States',
        'Canada',
        'Asia',
        'Japan',
        'Australia'
      ]

      def code
        COUNTRY_CODES_HASH[location.to_sym]
      end
    end

    class_methods do
      def location_to_code(val)
        COUNTRY_CODES_HASH[val.to_sym]
      end

      def code_to_location(val)
        COUNTRY_CODES_HASH.key(val).to_s
      end
    end

    COUNTRY_CODES_HASH = {
      'Europe': 'Europe',
      'European Union': 'EuropeanUnion',
      'Ireland': 'IE',
      'Germany': 'DE',
      'France': 'FR',
      'Greece': 'GR',
      'Italy': 'IT',
      'Spain': 'ES',
      'Russian Federation': 'RU',

      'N. and S. America': 'Americas',
      'United States': 'US',
      'Canada': 'CA',

      'Asia': 'Asia',
      'Japan': 'JP',
      'Australia': 'AU'
    }.freeze
  end
end
