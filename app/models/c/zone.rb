# frozen_string_literal: true

module C
  class Zone < ApplicationRecord
    has_many :countries

    validates :name, presence: true
  end
end
