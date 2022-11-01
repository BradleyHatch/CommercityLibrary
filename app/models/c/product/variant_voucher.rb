module C
  module Product
    class VariantVoucher < ApplicationRecord
      belongs_to :voucher
      belongs_to :variant

      validates :voucher, presence: true
      validates :variant, presence: true
    end
  end
end
