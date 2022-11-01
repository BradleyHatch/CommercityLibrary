# frozen_string_literal: true

module C
  class Testimonial < ApplicationRecord
    include Orderable

    validates :quote, :author, presence: true
    # not sure if can be removed
    belongs_to :project, optional: true
    belongs_to :content, optional: true

    def quote_teaser
      quote.truncate(150)
    end

    INDEX_TABLE = {
      'Quote': {
        link: {
          name: { call: 'quote' },
          options: '[:edit, object]'
        }
      },
      'Author': {
        call: 'author'
      },
      'Title': {
        call: 'title'
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
