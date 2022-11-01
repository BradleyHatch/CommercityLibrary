# frozen_string_literal: true

module C
  module Priceable
    extend ActiveSupport::Concern
    class_methods do
      def has_price(name=:price)
        belongs_to name, class_name: C::Price, dependent: :destroy
        accepts_nested_attributes_for name, reject_if: lambda { |p|
          tax = p[:with_tax].to_f
          notax = p[:without_tax].to_f
          Money.new(tax) <= 0 && Money.new(notax) <= 0
        }
      end
    end
  end
end
