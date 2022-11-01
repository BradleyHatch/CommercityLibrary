# frozen_string_literal: true

module Deko
  class Utils
    CAMELIZE_EXCEPTIONS = {
      api_key: 'api_key',
      installation_id: 'InstallationID'
    }.freeze

    def self.camelize(field_name)
      if CAMELIZE_EXCEPTIONS.key?(field_name)
        CAMELIZE_EXCEPTIONS[field_name]
      else
        field_name.to_s.split('_').collect(&:capitalize).join
      end
    end
  end
end
