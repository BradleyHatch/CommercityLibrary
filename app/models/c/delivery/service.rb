# frozen_string_literal: true

module C
  module Delivery
    class Service < ApplicationRecord
      include Orderable

      class NoRuleFound < RuntimeError; end
      class NoPriceFound < RuntimeError; end

      scope :for_cart_price, lambda { |cart_price = 0|
        joins(:rules).merge(
          Delivery::Rule.where(
            '(max_cart_price_pennies > ? OR max_cart_price_pennies IS NULL) AND
min_cart_price_pennies < ?',
            cart_price, cart_price
          )
        ).distinct
      }

      scope :for_cart_price_and_zone, lambda { |cart_price = 0, zone|
        joins(:rules).merge(
          Delivery::Rule.where(zone: zone).where(
            '(max_cart_price_pennies > ? OR max_cart_price_pennies IS NULL) AND
min_cart_price_pennies < ?',
            cart_price, cart_price
          )
        ).distinct
      }

      enum channel: %i[web ebay amazon]

      belongs_to :provider, class_name: 'C::Delivery::Provider'
      has_many :rules, class_name: 'C::Delivery::Rule', dependent: :destroy

      has_many :service_variants, class_name: 'C::Delivery::ServiceVariant', dependent: :destroy
      has_many :variants, through: :service_variants

      accepts_nested_attributes_for :rules,
                                    allow_destroy: true,
                                    reject_if: lambda { |attributes|
                                      attributes[:base_price].blank?
                                    }

      validates :name, :provider, :channel, :tax_rate, presence: true

      def service_name
        if display_name.present?
          display_name
        else
          "#{provider.name} #{name}"
        end
      end

      def price(weight = 0, zone = 0)
        rule = rules.find_by(zone: zone)
        if C.fallback_to_any_delivery_when_no_rule
          # there is no zoning for this delivery type, look for a fallback
          rule = rules.first unless rule
        end
        raise NoPriceFound unless rule
        pounds = rule.calculate_cost_from(weight)
        C::Price.new(with_tax_pennies: pounds * 100)
      end

      def price_for_cart_total_and_zone(cart_total, zone)
        rule = rules.where(zone: zone).find_by(
          '(max_cart_price_pennies >= ? OR max_cart_price_pennies IS NULL) AND
min_cart_price_pennies <= ?',
          cart_total, cart_total
        )
        raise NoPriceFound if rule.blank?
        C::Price.new(with_tax: rule.base_price)
      end

      def price_for_cart_total(cart_total)
        rule = rules.find_by(
          '(max_cart_price_pennies >= ? OR max_cart_price_pennies IS NULL) AND
min_cart_price_pennies <= ?',
          cart_total, cart_total
        )
        raise NoPriceFound if rule.blank?
        C::Price.new(with_tax: rule.base_price)
      end

      def max_cart_price(zone = nil)
        applicable = fetch_applicable_rules(zone)
        return nil if applicable.detect { |r| r.max_cart_price.nil? }
        applicable.max_by(&:max_cart_price).max_cart_price
      end

      def min_cart_price(zone)
        fetch_applicable_rules(zone).min_by(&:min_cart_price).min_cart_price
      end

      def fetch_applicable_rules(zone)
        result = rules.where(zone: zone)
        unless result.any?
          result = rules.order(base_price: :desc).limit(1)
          raise NoRuleFound if result.empty?
        end
        result
      end

      INDEX_TABLE = {
        'Name': { primary: 'name' },
        'Provider': { call: 'provider.name' }
      }.freeze
    end
  end
end
