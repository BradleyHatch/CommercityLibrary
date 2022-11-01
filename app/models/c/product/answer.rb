# frozen_string_literal: true

module C
  class Product::Answer < ApplicationRecord
    belongs_to :question
    has_one :variant, through: :question

    validates :question_id, presence: true
    validates :body, presence: true

    scope :sent, -> { where(sent: true) }
  end
end
