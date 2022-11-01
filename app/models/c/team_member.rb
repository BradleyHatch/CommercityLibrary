# frozen_string_literal: true

module C
  class TeamMember < ApplicationRecord
    include Orderable

    validates :name, presence: true

    mount_uploader :image, ImageUploader

    def name_and_role
      role_text = role.present? ? " - #{role}" : ''
      "#{name}#{role_text}"
    end

    INDEX_TABLE = {
      'Image': {
        image: 'image.preview'
      },
      '': {},
      'Name': {
        link: {
          name: { call: 'name_and_role' },
          options: '[:edit, object]'
        }
      },
      'Edit': {
        link: {
          name: { text: 'Edit' },
          options: '[:edit, object]'
        }
      }
    }.freeze
  end
end
