# frozen_string_literal: true

module C
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Call from the ApplicationController to set any author or
    # updated by user values when present
    cattr_accessor :author

    before_validation :created_by_user=, on: :create
    before_save :updated_by_user=

    def self.use_raw_id!
      @_use_raw_id = true
    end

    def self.use_pretty_id!
      @_use_raw_id = false
    end

    def self.use_raw_id?
      @_use_raw_id ||= false
    end

    private

    def created_by_user=
      self.created_by = author if respond_to?(:created_by) && author.present?
    end

    def updated_by_user=
      self.updated_by = author if respond_to?(:updated_by) && author.present?
    end
  end
end
