# frozen_string_literal: true

module C
  class MenuItem < ApplicationRecord
    acts_as_tree order: 'weight'

    validates :machine_name, presence: true
    validates :name, presence: true

    belongs_to :content

    before_validation on: :create do
      self.machine_name = name
    end

    # Force non blank parametized machine name
    def machine_name=(val)
      super val.to_s.parameterize
    end
  end
end
