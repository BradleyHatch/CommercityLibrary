module C
  class Collection < ApplicationRecord
    include Sluggable
    include Pageinfoable

    enum collection_type: %i[product category]

    has_many :collection_variants, class_name: 'C::CollectionVariant', dependent: :destroy
    has_many :variants, through: :collection_variants, class_name: 'C::Product::Variant'

    has_many :collection_categories, class_name: 'C::CollectionCategory', dependent: :destroy
    has_many :categories, through: :collection_categories, class_name: 'C::Category'

    validates :name, presence: true

    mount_uploader :image, CategoryImageUploader
    mount_uploader :image_alt, CategoryImageUploader

    def view
    end

    INDEX_TABLE = {
      'Collection': {
        link: {
          name: {
            call: 'name'
          },
          options: '[:edit, object]'
        },
        sort: 'name'
      },
      'Products': {
        call: 'variants.size'
      },
      'View': {
        call: 'view'
      },
      'Edit': {
        link: {
          name: {
            text: 'edit'
          },
          options: '[:edit, object]'
        }
      }
    }.freeze

  end
end
