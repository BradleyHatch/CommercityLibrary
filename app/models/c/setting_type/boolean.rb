# frozen_string_literal: true

module C
  module SettingType
    class Boolean < ApplicationRecord
      include SettingType

      def form_helper
        :check_box
      end

      def type
        :boolean
      end

      def value
        self[:value]
      end
    end
  end
end
