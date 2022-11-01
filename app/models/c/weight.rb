# frozen_string_literal: true

module C
  class Weight < ApplicationRecord
    belongs_to :orderable, polymorphic: true

    def value
      super || 0
    end
  end
end
