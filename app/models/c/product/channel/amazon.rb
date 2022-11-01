
# frozen_string_literal: true

module C
  module Product
    module Channel
      class Amazon < ApplicationRecord
        include C::Channel

        has_many :amazon_search_terms,
                 class_name: 'Product::Channel::AmazonSearchTerm',
                 dependent: :destroy, foreign_key: :product_channel_id
        accepts_nested_attributes_for :amazon_search_terms,
                                      allow_destroy: true,
                                      reject_if: ->(term) { term[:term].blank? }

        has_many :bullet_points,
                 class_name: 'Product::Channel::AmazonBulletPoint',
                 dependent: :destroy,
                 foreign_key: :product_channel_id
                 
        accepts_nested_attributes_for :bullet_points,
                                      allow_destroy: true,
                                      reject_if: lambda { |term|
                                        term[:value].blank?
                                      }

        has_many :amazon_browse_node_categorizations,
                 class_name: 'C::AmazonBrowseNodesCategorization',
                 foreign_key: :amazon_channel_id
        accepts_nested_attributes_for :amazon_browse_node_categorizations
        has_many :amazon_browse_nodes,
                 through: :amazon_browse_node_categorizations

        belongs_to :product_type, class_name: C::AmazonProductType
        belongs_to :amazon_category

        mount_uploader :ebc_logo, ImageUploader
        mount_uploader :ebc_module2_image, ImageUploader

        with_options if: :testing_completeness? do
          validates :own_description, length: { maximum: 2000 }
          validates :amazon_browse_nodes, length: { maximum: 2 }
          validates :bullet_points, length: { maximum: 5 }

          if (ENV['USE_AMAZON_PRODUCT_PIPELINE'])
            validates :product_type, presence: true
            validates :amazon_category, presence: true
          end
        end

        after_destroy do
          next unless ENV['USE_AMAZON_PRODUCT_PIPELINE']
          C::AmazonPipeline.destroy(master.variants.where.not(amazon_product_pipeline_id: nil))
        end

        def testing_completeness?
          if master
            @testing_completeness
          else
            false
          end
        end

        def complete_and_valid?
          @testing_completeness = true
          valid?
        end

        # validate :amazon_browse_nodes_count
        # validate :bullet_points_count

        monetize :current_price_pennies, allow_nil: true
        monetize :de_price_pennies
        monetize :es_price_pennies
        monetize :fr_price_pennies
        monetize :it_price_pennies
        monetize :shipping_cost_pennies

        publishable? do
          validates :name, presence: true, length: { minimum: 1_000_000 }
        end

        EBC_FIELDS = %i[
          ebc_logo ebc_description ebc_module1_heading ebc_module1_body ebc_module2_heading
          ebc_module2_sub_heading ebc_module2_body ebc_module2_image
        ]

        def ebc_fields
          EBC_FIELDS.map { |f| [f, self[f]] }.to_h
        end

        def ebc_valid?
          ebc_fields.all? { |k, v| v.present? }
        end
      end
    end
  end
end
