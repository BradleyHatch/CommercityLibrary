# frozen_string_literal: true

# Model for all page content across commercity

module C
  class Content < ApplicationRecord
    include Pageinfoable
    include ContentImageable
    include Sluggable
    include Documentable
    include TemplatePageable

    enum content_type: %i[basic_page service blog location project]

    scope :published, (-> { where(published: true) })
    scope :featured, (-> { where(featured: true) })

    belongs_to :created_by, class_name: 'C::User', required: false
    belongs_to :updated_by, class_name: 'C::User', required: false

    has_many :menu_items, autosave: true, dependent: :destroy

    accepts_nested_attributes_for :menu_items

    validates :name, presence: true
    validates :content_type, presence: true

    acts_as_tree order: 'weight'

    # Return the default show template if not defined
    def template
      super.blank? ? 'show' : super
    end

    def self.from_type(url)
      content, slug = url.split('/')
      if content_types.keys.include?(content)
        send(content).find_by!(slug: slug)
      else
        find_by!(slug: url)
      end
    end

    def name_with_depth
      root? ? name : "- #{name}"
    end

    INDEX_TABLE = {
      'Name': { primary: 'name_with_depth' },
      'Author': { call: 'created_by&.name', sort: 'author' },
      'Published': { call: 'published', sort: 'published' },
      'Created': { call: 'created_at', sort: 'published' }
    }.freeze
  end
end
