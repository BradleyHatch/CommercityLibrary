# frozen_string_literal: true

module C
  class AmazonBrowseNode < ApplicationRecord
    has_many :amazon_browse_node_categorizations,
             class_name: 'C::AmazonBrowseNodesCategorization'
    has_many :amazon_channels,
             through: :amazon_browse_node_categorizations,
             class_name: 'C::Product::Channel::Amazon'

    validates :name, presence: true
    validates :node_id, presence: true
    validates :node_path, presence: true
  end
end
