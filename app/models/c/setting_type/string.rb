# frozen_string_literal: true

module C
  module SettingType
    class String < ApplicationRecord
      include SettingType

      def form_helper
        :text_field
      end

      def type
        :string
      end
    end
  end
end
