module C
  class PriceChange < ApplicationRecord
    monetize :with_tax_pennies
    monetize :without_tax_pennies
    
    monetize :was_with_tax_pennies
    monetize :was_without_tax_pennies

    belongs_to :price
    belongs_to :user, optional: true


  end
end
