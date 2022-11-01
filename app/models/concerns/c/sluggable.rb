# frozen_string_literal: true

module C
  module Sluggable
    extend ActiveSupport::Concern
    included do
      validates :slug, presence: true, uniqueness: true, unless: 'name.blank?'
      before_validation :ensure_unique_slug

      def to_param(override=nil)
        case override
        when :admin
          id.to_s
        when :front
          slug
        when nil
          ApplicationRecord.use_raw_id? ? super() : slug
        else
          raise ArgumentError, 'Unknown override ' + override.to_s
        end
      end

      # Gets the record fvaror the pretty url
      # if two path url (eg seomthing/else) then looks to see if
      # placed in content type
      def self.from_url(url)
        return find_by!(home: true) if url.blank?
        if self.class.name == 'C::Content' && url.split('/').length == 2
          from_type(url)
        else
          find_by!(slug: url)
        end
      rescue ActiveRecord::RecordNotFound
        find(url)
      end

      private

      # If name is not unique, prevent the same slug from being created by
      # incrementing a value and appending it to end of slug
      def ensure_unique_slug
        return if slug.present? || name.blank?
        self.slug = name.parameterize
        i = 0
        while self.class.unscoped.exists?(slug: slug)
          self.slug = "#{name.parameterize}-#{i += 1}"
        end
      end
    end
  end
end
