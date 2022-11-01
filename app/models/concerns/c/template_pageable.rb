# frozen_string_literal: true

module C
  module TemplatePageable
    extend ActiveSupport::Concern
    included do

      belongs_to :template_group, class_name: 'C::Template::Group'
      has_many :regions, class_name: 'C::Template::Region', through: :template_group

      def get_group_from_family
        return template_group if template_group_id.present?
        parent.get_group_from_family if parent_id.present?
      end

    end
  end
end
