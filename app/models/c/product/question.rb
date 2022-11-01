# frozen_string_literal: true

module C
  class Product::Question < ApplicationRecord
    include Notifiable

    after_create :notify

    belongs_to :variant
    has_many :answers

    validates :variant_id, presence: true
    validates :source, presence: true

    enum source: %i[web ebay amazon]

    scope :ordered, -> { order(created_at: :desc) }
    scope :answered, -> { where(answered: true) }
    scope :unanswered, -> { where(answered: false) }

    def display_sender
      if source == 'ebay'
        "Ebay user '#{sender_id}'"
      else
        ''
      end
    end

    def display_subject
      if source == 'ebay'
        "Question from #{display_sender}"
      else
        ''
      end
    end
  end
end
