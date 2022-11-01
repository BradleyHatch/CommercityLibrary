# frozen_string_literal: true

require 'deko/utils'

module Deko
  ##
  # Each RequestArgument subclass initializer takes a hash and constructs
  # dynamic fields based on its +fields+ argument. Minimal validation for
  # required arguments is configured with +required_fields+.
  class RequestArgument
    def initialize(data = {})
      @data = data
    end

    def parameterize_field_name(field_name)
      "#{class_name}[#{Utils.camelize(field_name)}]"
    end

    def class_name
      name = self.class.to_s
      if (index = name.rindex('::'))
        name[(index + 2)..-1]
      else
        name
      end
    end

    ##
    # Serializes the data in a Deko-friendly format.
    def to_params
      params = {}
      fields.each do |field|
        begin
          value = @data.fetch(field)
          raise RequiredFieldMissingError, field unless value
          params[parameterize_field_name(field)] = value
        rescue KeyError
          next unless required_fields.include?(field)
          raise RequiredFieldMissingError, field
        end
      end
      params
    end

    def required_fields
      []
    end
  end

  class RequiredFieldMissingError < RuntimeError
    def initialize(field_name = nil)
      super("Missing '#{field_name}'")
    end
  end

  class Identification < RequestArgument
    def fields
      %i[api_key installation_id retailer_unique_ref].freeze
    end

    def required_fields
      %i[api_key installation_id].freeze
    end

    def initialize(data = {})
      default_fields = {
        api_key: ENV['DEKO_API_KEY'],
        installation_id: ENV['DEKO_INSTALLATION_ID']
      }
      @data = default_fields.merge(data)
    end

    def retailer_unique_ref
      @data[:retailer_unique_ref]
    end
  end

  class Finance < RequestArgument
    def fields
      %i[code deposit].freeze
    end

    def required_fields
      %i[code deposit].freeze
    end
  end

  class Goods < RequestArgument
    def fields
      %i[description price].freeze
    end

    def required_fields
      %i[description price].freeze
    end
  end

  class Consumer < RequestArgument
    # From Deko documentation
    MOBILE_REGEX = /
      (^\+[0-9]{2}|^\+[0-9]{2}\(0\)|^\(\+[0-9]{2}\)\(0\)|^00[0-9]{2}|^0)
      ([0-9]{9}$|[0-9\-\s]{10}$)
    /x

    def initialize(*args)
      super
      exclude_mobile_if_invalid
    end

    def exclude_mobile_if_invalid
      mobile_number = @data[:mobile_number]
      return if mobile_number&.match?(MOBILE_REGEX)
      @data.delete(:mobile_number)
    end

    def fields
      %i[title forename surname email_address mobile_number]
    end
  end
end
