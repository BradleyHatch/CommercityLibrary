# frozen_string_literal: true

module C
  module PagesHelper
    def meta_tags
      safe_join([page_title, meta_description]) if @_page_info
    end

    def page_title
      content_tag(:title, @_page_info.constructed_page_title)
    end

    def meta_description
      return if @_page_info.meta_description.blank?
      tag :meta, name: :description, content: @_page_info.meta_description
    end
  end
end
