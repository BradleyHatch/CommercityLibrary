
# frozen_string_literal: true

module C
  module Product
    module Channel
      class Web < ApplicationRecord
        include C::Channel

        monetize :current_price_pennies, allow_nil: true
        monetize :discount_price_pennies, allow_nil: true
      end
    end
  end
end
