# frozen_string_literal: true

module C
  class UserRole < ApplicationRecord
    belongs_to :user
    belongs_to :role
  end
end
