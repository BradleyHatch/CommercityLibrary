# frozen_string_literal: true

module C
  class NonDelete < ApplicationRecord
    belongs_to :deletable, polymorphic: true

    def readonly?
      false
    end
  end
end
