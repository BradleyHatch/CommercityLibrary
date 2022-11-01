# frozen_string_literal: true

module C
  module SettingType
    class Image < ApplicationRecord
      include SettingType

      mount_uploader :default, ImageUploader
      mount_uploader :value, ImageUploader

      def form_helper
        :file_field
      end

      def type
        if setting.value.respond_to? :file
          :image
        else
          :string
        end
      end

      def default
        default_string if super.file.blank?
        super
      end

      def default=(val)
        self.default_string = val
        super
      end

      def value_present?
        value.file.present?
      end
    end
  end
end
