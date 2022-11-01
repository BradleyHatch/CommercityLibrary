# frozen_string_literal: true

module C
  class PageInfo < ApplicationRecord
    belongs_to :page, polymorphic: true

    def fallback_title
      if (name = page.try(:name))
        "#{name} | #{C.store_name}"
      else
        C.store_name
      end
    rescue
      ''
    end

    def title
      super || ''
    end

    def constructed_page_title
      title.blank? ? "#{title_from_name}#{C.store_name}" : title
    end

    private

    def title_from_name
      "#{page.name} | " if page.respond_to? :name
    end
  end
end
