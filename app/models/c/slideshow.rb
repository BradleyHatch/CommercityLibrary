# frozen_string_literal: true

module C
  class Slideshow < ApplicationRecord
    scope :ordered, -> { order created_at: :asc }

    has_many :slides, dependent: :delete_all

    validates :name, presence: true

    before_validation on: :create do
      self.machine_name = name
    end

    # Force non blank parametized machine name
    def machine_name=(val)
      super val.to_s.parameterize
    end

    INDEX_TABLE = {
      'Name': { primary: 'name' },
      'Description': { call: 'body&.html_safe' }
    }.freeze
  end
end
