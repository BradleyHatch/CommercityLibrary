# frozen_string_literal: true

module C
  class BundleItem < ApplicationRecord
    belongs_to :bundled_variant, class_name: 'C::Product::Variant'
    belongs_to :variant, class_name: 'C::Product::Variant'

    validates :bundled_variant, presence: true
    validates :variant, presence: true
    monetize :web_price_pennies
    monetize :ebay_price_pennies
    monetize :amazon_price_pennies

    def web_tax
      (web_price / (1 + (variant.master.tax_rate / 100))) * (variant.master.tax_rate / 100)
    end

    def web_price_without_tax
      web_price - web_tax
    end

    def web_price_pennies_without_tax
      web_price_without_tax.fractional
    end

    def ebay_tax
      (ebay_price / (1 + (variant.master.tax_rate / 100))) * (variant.master.tax_rate / 100)
    end

    def ebay_price_without_tax
      ebay_price - ebay_tax
    end

    def ebay_price_pennies_without_tax
      ebay_price_without_tax.fractional
    end

    def amazon_tax
      (amazon_price / (1 + (variant.master.tax_rate / 100))) * (variant.master.tax_rate / 100)
    end

    def amazon_price_without_tax
      amazon_price - amazon_tax
    end

    def amazon_price_pennies_without_tax
      amazon_price_without_tax.fractional
    end

    def web_price_ratio
      web_price_pennies.to_f / variant.price(channel: :web).fractional
    end

    def ebay_price_ratio
      ebay_price_pennies.to_f / variant.price(channel: :ebay).fractional
    end

    def amazon_price_ratio
      amazon_price_pennies.to_f / variant.price(channel: :amazon).fractional
    end
  end
end
