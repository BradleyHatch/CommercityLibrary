# frozen_string_literal: true

module C
  module Product
    class ChannelImage < ApplicationRecord
      include Orderable

      default_scope -> { includes(:image) }
      belongs_to :channel, polymorphic: true
      belongs_to :image
    end
  end
end
