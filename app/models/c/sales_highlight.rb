# frozen_string_literal: true

module C
  class SalesHighlight < ApplicationRecord
    include Orderable

    validates :image, presence: true
    mount_uploader :image, ImageUploader

    INDEX_TABLE = {
      'Image': {
        image: 'image.preview'
      },
      'URL': {
        call: 'url'
      },
      'Edit': {
        link: {
          name: {
            text: 'Edit'
          },
          options: '[:edit, object]'
        }
      }
    }.freeze
  end
end
