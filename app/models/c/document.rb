# frozen_string_literal: true

module C
  class Document < ApplicationRecord
    mount_uploader :document, C::FileUploader
    validates :document, presence: true
    belongs_to :documentable, polymorphic: true

    def self.bulk_upload(documents)
      count = 0
      documents.each do |attachment|
        document = new(
          name: attachment[:attachment].original_filename,
          document: attachment[:attachment]
        )
        count += 1 if document.save
      end
      count
    end

    # TODO: show the stuff as links
    INDEX_TABLE = {
      'Name': { link: { name: { call: 'name' }, options: 'document.url' }},
      'File': {
        call: 'document.url'
      },
      'Created': {
        call: 'created_at'
      },
      'Delete': {
        link: {
          name: {
            text: 'Delete'
          },
          options: '[object]',
          method: :delete,
          data: {
            confirm: 'Are you sure?'
          }
        }
      }
    }.freeze
  end
end
