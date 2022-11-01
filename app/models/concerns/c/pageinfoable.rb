# frozen_string_literal: true

module C
  module Pageinfoable
    extend ActiveSupport::Concern
    included do
      has_one :page_info, as: :page, dependent: :destroy, autosave: true

      delegate :title, to: :page_info
      delegate :title=, to: :page_info

      delegate :meta_description, to: :page_info
      delegate :meta_description=, to: :page_info

      def page_info
        super || build_page_info
      end
    end
  end
end
