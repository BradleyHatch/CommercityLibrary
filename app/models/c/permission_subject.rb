# frozen_string_literal: true

module C
  class PermissionSubject < ApplicationRecord
    validates :name, presence: true

    def subject
      subject_type.constantize
    rescue NameError
      subject_type
    end
  end
end
