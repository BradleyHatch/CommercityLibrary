# frozen_string_literal: true

module C
  class Address < ApplicationRecord
    before_validation :set_name

    attr_accessor :address_type

    belongs_to :customer, optional: true
    belongs_to :country

    delegate :name, to: :country, prefix: true, allow_nil: true

    # validations
    validates :name, presence: true
    validates :address_one, presence: true
    validates :city, presence: true
    validates :postcode, presence: true
    validates :country, presence: true

    before_save :ensure_postcode_format

    def ensure_postcode_format
      self.postcode.strip!
      self.postcode.upcase!

      # if is of format 'letter letter num num num letter letter', shove a space after the 4th character
      # e.g. 'TF232LZ' would become 'TF23 2LZ'
      if self.postcode =~ /[a-z][a-z]\d\d\d[a-z][a-z]/i
        self.postcode.insert(4, ' ')

      # if is of format 'letter letter num num letter letter', shove a space after the 3th character
      # e.g. 'TF22LZ' would become 'TF2 2LZ'
      elsif self.postcode =~ /[a-z][a-z]\d\d[a-z][a-z]/i
        self.postcode.insert(3, ' ')
      end
    end

    def full_address_array
      [name,
       address_one,
       address_two,
       address_three,
       city,
       region,
       postcode,
       country_name].reject(&:blank?)
    end

    def full_address
      full_address.join(', ')
    end

    def short_address
      [address_one, address_two, address_three].reject(&:blank?).join(', ')
    end

    def set_name
      self.name = "#{first_name} #{last_name}" if name.blank?
    end

  end
end
