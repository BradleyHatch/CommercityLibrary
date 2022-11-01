# frozen_string_literal: true

module C
  module SettingType
    extend ActiveSupport::Concern

    def self.table_name_prefix
      'c_setting_type_'
    end

    included do
      has_one :setting, as: :data

      def value_present?
        self[:value].present?
      end

      def value
        value_present? ? super : default
      end
    end
  end
end
