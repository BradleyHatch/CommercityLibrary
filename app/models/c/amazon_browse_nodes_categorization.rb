# frozen_string_literal: true

module C
  class AmazonBrowseNodesCategorization < ApplicationRecord
    belongs_to :amazon, class_name: 'Product::Channel::Amazon',
                        validate: true

    belongs_to :amazon_browse_node, class_name: 'AmazonBrowseNode',
                                    validate: true
  end
end
