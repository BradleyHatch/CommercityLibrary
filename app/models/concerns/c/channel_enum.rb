# frozen_string_literal: true

module C
  module ChannelEnum
    extend ActiveSupport::Concern

    included do
      enum channel: %w[amazon ebay web manual]
    end
  end
end
