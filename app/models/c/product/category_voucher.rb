module C
  class Product::CategoryVoucher < ApplicationRecord
    belongs_to :category, optional: false
    belongs_to :voucher, optional: false
  end
end
