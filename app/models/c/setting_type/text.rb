# frozen_string_literal: true

module C
  module SettingType
    class Text < ApplicationRecord
      include SettingType

      def form_helper
        :text_area
      end

      def type
        :text
      end
    end
  end
end
