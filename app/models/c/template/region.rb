# frozen_string_literal: true

module C
  module Template
    class Region < ApplicationRecord
      include Orderable

      belongs_to :group, class_name: 'C::Template::Group'

      has_many :blocks, class_name: 'C::Template::Block', dependent: :destroy

      validates :name, presence: true

      INDEX_TABLE = {
        '': {},
        'Name': {
          link: {
            name: { call: 'name' },
            options: '[:edit, object.group, object]'
          }
        },
        'Edit': {
          link: {
            name: { text: 'Edit' },
            options: '[:edit, object.group, object]'
          }
        }
      }.freeze

    end
  end
end
