# frozen_string_literal: true

module C
  class Permission < ApplicationRecord
    belongs_to :role
    belongs_to :permission_subject

    delegate :name, :body, :subject, :subject_id, to: :permission_subject
  end
end
