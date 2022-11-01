# frozen_string_literal: true

module C
  module Payable
    extend ActiveSupport::Concern

    included do
      has_one :payment, as: :payable, class_name: 'C::Order::Payment'
      has_one :cart, through: :payment
      has_one :order, through: :payment

      has_paper_trail if: proc { PaperTrail.whodunnit.present? }
    end

    def paid?
      false
    end

    def off_site_confirmation?
      false
    end

    def cancel!
      # Do nothing
    end
  end
end
