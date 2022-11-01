# frozen_string_literal: true

module C
  class SettingGroup < ApplicationRecord
    validates :name, presence: true
    validates :machine_name, presence: true

    has_many :settings, dependent: :destroy

    before_validation on: :create do
      self.machine_name = name
    end

    # Force non blank parametized machine name
    def machine_name=(val)
      super val.to_s.parameterize
    end
  end
end
