# frozen_string_literal: true

module C
  class Redirect < ApplicationRecord
    scope :ordered, -> { order created_at: :desc }

    validates :old_url, presence: true
    validates :new_url, presence: true

    def increment
      self.used_counter = used_counter + 1
      self.last_used = Time.zone.now
      save!
    end

    def self.bulk(action)
      case action
      when 'delete'
        destroy_all
        'Deleted Redirects'
      else
        'No action selected'
      end
    end

    INDEX_TABLE = {
      'Old URL': {
        call: 'old_url',
        sort: 'old_url'
      },
      'New URL': {
        call: 'new_url',
        sort: 'new_url'
      },
      'Used': {
        call: 'used_counter',
        sort: 'used_counter'
      },
      'Last Used': {
        call: 'last_used',
        sort: 'last_used'
      },
      'Edit': {
        link: {
          name: {
            text: 'edit'
          },
          options: '[:edit, object]'
        }
      }
    }.freeze
  end
end
