# frozen_string_literal: true

module C
  module ContentImageable
    extend ActiveSupport::Concern

    included do
      has_many :images, as: :imageable, autosave: true, dependent: :destroy
      has_one :feature_image, ->  { where(featured_image: true) },
              as: :imageable, class_name: 'C::Image'
      has_one :preview_image, ->  { where(preview_image: true) },
              as: :imageable, class_name: 'C::Image'

      accepts_nested_attributes_for :images, allow_destroy: true

      def new_images=(val)
        Array(val).each do |image|
          images.build(image: image)
        end
      end

      def feature_image(fallback=nil)
        super&.image || images.first&.image || fallback || ''
      end

      def preview_image(fallback=nil)
        super&.image || images.first&.image || fallback || ''
      end
    end
  end
end
