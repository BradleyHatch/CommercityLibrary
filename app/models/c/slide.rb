# frozen_string_literal: true

module C
  class Slide < ApplicationRecord
    include Orderable

    belongs_to :slideshow

    validates :slideshow, presence: true
    validates :image, presence: true

    mount_uploader :image, ImageUploader

    INDEX_TABLE = {
      'Slide': {
        image: 'image.preview'
      },
      'Name': {
        link: {
          name: {
            call: 'name'
          },
          options: '[:edit, object.slideshow, object]'
        }
      },
      'Edit': {
        link: {
          name: {
            text: 'Edit'
          },
          options: '[:edit, object.slideshow, object]'
        }
      }
    }.freeze
  end
end
