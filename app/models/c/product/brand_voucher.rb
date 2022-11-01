module C
  class Product::BrandVoucher < ApplicationRecord
    belongs_to :brand, optional: false
    belongs_to :voucher, optional: false
  end
end
