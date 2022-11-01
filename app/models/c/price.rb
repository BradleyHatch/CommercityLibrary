# frozen_string_literal: true

module C
  class Price < ApplicationRecord
    monetize :with_tax_pennies
    monetize :without_tax_pennies

    delegate :zero?, to: :with_tax

    has_paper_trail if: proc { PaperTrail.whodunnit.present? }

    has_many :price_changes, dependent: :destroy

    # make sure both with and without tax didnt change unless
    # override is set to true
    validate do
      if !override? && with_tax_pennies_changed? && without_tax_pennies_changed?
        errors[:base] << 'You cant change with tax price and without tax price
                          without overriding them.'
      end
    end

    before_save do
      next if override?

      # Validation ensures that both prices can't be set at once, unless
      # override is set, which we guard for above.
      if without_tax_pennies_changed?
        self.with_tax = without_tax * tax_multiplier
      elsif with_tax_pennies_changed?
        self.without_tax = with_tax / tax_multiplier
      end
    end

    after_save do
      if self.without_tax_pennies_changed? || self.with_tax_pennies_changed? || self.tax_rate_changed?
        save_price_change
      end
    end

    def save_price_change
      price_changes.create(
        without_tax_pennies: self.without_tax_pennies,
        with_tax_pennies: self.with_tax_pennies,
        tax_rate: self.tax_rate,
        #############################################################
        was_without_tax_pennies: self.without_tax_pennies_was,
        was_with_tax_pennies: self.with_tax_pennies_was,
        was_tax_rate: self.tax_rate_was,
        #############################################################
        changed_at: Time.now
      )
    end

    def tax_multiplier
      (100 + tax_rate) / 100
    end

    def tax
      with_tax - without_tax
    end

    # The usual dupe method fails unless the original has override: true
    # This duplicates and saves a price while preserving the override value
    def create_dup
      new_attributes = attributes.except('id', 'created_at', 'updated_at')
      new_attributes['override'] = true
      result = C::Price.create!(new_attributes)
      result.update(override: override)
      result
    end
  end
end
