# frozen_string_literal: true

module C
  # Storing countries used for delivery and billing
  class Country < ApplicationRecord
    # prevent deleting country if address associated
    has_many :addresses, dependent: :restrict_with_exception
    has_many :variants, class_name: 'C::Product::Variant',
                        foreign_key: :country_of_manufacture_id,
                        dependent: :restrict_with_exception
    belongs_to :zone

    # default order sorts alphabetically
    scope :ordered, -> { order(name: :asc) }
    scope :active, -> { where(active: true) }

    scope :pick_ordered, -> { order("iso2 = 'GB' DESC, name ASC") }

    # validations
    validates :name, presence: true
    validates :numeric, presence: true, length: { is: 3 }, format: /\d{3}/

    INDEX_TABLE = {
      'Active?': { toggle: { condition: 'active?',
                             true: { link: { name: { text: 'Yes' }, options: '[:toggle_state, object]' } },
                             false: { link: { name: { text: 'No' }, options: '[:toggle_state, object]' } } } },
      'Name': { call: 'name' },
      'ISO2': { call: 'iso2' },
      'ISO3': { call: 'iso3' },
      'TLD': { call: 'tld' },
      'Currency': { call: 'currency' },
      'Zone': { link: { name: { call: 'zone.name' }, options: '[:edit, object]' } },
      'EU?': { toggle: { condition: 'eu?', true: { text: 'yes' }, false: { text: 'no' } } }

    }.freeze
  end
end
