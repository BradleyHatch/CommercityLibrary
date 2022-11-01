module C
  class Page < ApplicationRecord
    has_one :page_info, as: :page, dependent: :destroy
    accepts_nested_attributes_for :page_info

    has_one :menu_item, autosave: true
    accepts_nested_attributes_for :menu_item

    delegate :title=, to: :page_info
    delegate :meta_description=, to: :page_info
    delegate :published=, to: :page_info
    delegate :protected=, to: :page_info
    delegate :home_page=, to: :page_info

    delegate :protected, to: :page_info
    delegate :published, to: :page_info
    delegate :home_page, to: :page_info
    delegate :home_page?, to: :page_info
    delegate :title, to: :page_info
    delegate :meta_description, to: :page_info
    delegate :author, to: :page_info

    has_many :images, as: :imageable, autosave: true, dependent: :destroy
    has_one :feature_image, ->  { where(featured_image: true) },
            as: :imageable, class_name: 'C::Image'
    has_one :preview_image, ->  { where(preview_image: true) },
            as: :imageable, class_name: 'C::Image'

    has_one :author_record, as: :authored, autosave: true, dependent: :destroy
    delegate :user, to: :author_record
    delegate :author, to: :author_record, allow_nil: true

    has_many :documents, as: :documentable, autosave: true,
             dependent: :destroy

    acts_as_tree order: 'weight'


    has_many :menu_items

  end
end


class ConvertOldPageContentToNewContent < ActiveRecord::Migration[5.0]
  def up
    C::Page.all.each do |page|
      content = C::Content.basic_page.create!(
        name: page.name,
        body: page.body,
        template: page.layout.blank? ? nil : page.layout,
        summary: '',
        parent_id: page.parent_id,
        weight: page.weight,
        slug: page.url_alias,
        published: page.published,
        protected: page.protected,
        root: page.home_page,
        created_at: page.created_at,
        updated_at: page.updated_at
      )
      page.images.each do |image|
        image.update(imageable_id: content.id, imageable_type: 'C::Content')
      end
      page.page_info.update(page_type: 'C::Content', page_id: content.id)
      page.documents.each do |doc|
        doc.update(documentable_id: content.id, documentable_type: 'C::Content')
      end
    end
  end
end
