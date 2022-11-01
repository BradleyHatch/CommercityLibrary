# frozen_string_literal: true

module C
  class CustomValue < ApplicationRecord
    validates :custom_field, presence: true
    validates :custom_recordable, presence: true

    belongs_to :custom_field, class_name: 'C::CustomField'

    belongs_to :custom_recordable, polymorphic: true
  end
end
