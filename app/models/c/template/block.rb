# frozen_string_literal: true

module C
  module Template
    class Block < ApplicationRecord
      include Orderable
      include ContentImageable

      enum size: %i[small medium big thin]
      enum kind_of: %i[text image slideshow]

      belongs_to :region, class_name: 'C::Template::Region'

      validates :name, presence: true

      mount_uploader :image, ImageUploader

      def get_html_class
        map = { small: 'g-1', medium: 'g-2', big: 'g-3', thin: 'g-1 thin' }
        size.blank? ? map[:small] : map[size.to_sym]
      end

      def get_image
        images.any? ? images.ordered.first.image : nil
      end

      INDEX_TABLE = {
        '': {
          image: 'image.preview'
        },
        'Name': {
          link: {
            name: { call: 'name' },
            options: '[:edit, object.region.group, object.region , object]'
          }
        },
        'Edit': {
          link: {
            name: { text: 'Edit' },
            options: '[:edit, object.region.group, object.region , object]'
          }
        }
      }.freeze

    end
  end
end
