# frozen_string_literal: true

module C
  class CustomField < ApplicationRecord
    has_many :values, class_name: 'C::CustomValue', dependent: :destroy

    validates :name, presence: true, uniqueness: true

    before_validation do
      name&.downcase!
    end

    INDEX_TABLE = {
      'Name': { link: { name: { call: 'name' }, options: '[:edit, object]' }, sort: 'name' },
      'Edit': { link: { name: { text: 'edit' }, options: '[:edit, object]' } }

    }.freeze
  end
end
