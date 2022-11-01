# frozen_string_literal: true

module C
  module Order
    class Payment < ApplicationRecord
      has_one :cart
      has_one :order, class_name: C::Order::Sale

      belongs_to :payable, polymorphic: true
      accepts_nested_attributes_for :payable

      monetize :amount_paid_pennies

      delegate :finalize!, :paid?, to: :payable
      delegate :cancel!, to: :payable, allow_nil: true

      has_paper_trail if: proc { PaperTrail.whodunnit.present? }

      def payment_method_name
        payable_type.split('::').last.titlecase if payable_type.present?
      end

      def build_payable(params = {})
        self.payable = C::PaymentMethod::Manual.new(params)
      end

      def fulfil
        payable.try(:fulfil)
      end
    end
  end
end
