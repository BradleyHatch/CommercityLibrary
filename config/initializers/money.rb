require 'eu_central_bank'

# rubocop:disable all
# encoding : utf-8
MoneyRails.configure do |config|

  # To set the default currency
  #
  config.default_currency = :gbp

  # set the seconds after than the current rates are automatically expired
  # # by default, they never expire
  Money::Bank::GoogleCurrency.ttl_in_seconds = 86400

  # Set default bank object
  #
  # Example:
  eu_bank = EuCentralBank.new

  Thread.new { 
    begin
      puts "- updating rates"
      eu_bank.update_rates
    rescue => e
      puts e
    end
  }
  
  config.default_bank = eu_bank

  # Add exchange rates to current.monetize bank object.
  # (The conversion rate refers to one direction only)
  #
  # Example:
  # config.add_rate "USD", "CAD", 1.24515
  # config.add_rate "CAD", "USD", 0.803115

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  # config.include_validations = true

  # Default ActiveRecord migration configuration values for columns:
  #
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_pennies',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: 'USD'
  #                          }

  # Register a custom currency
  #
  # Example:
  # config.register_currency = {
  #   :priority            => 1,
  #   :iso_code            => "EU4",
  #   :name                => "Euro with subunit of 4 digits",
  #   :symbol              => "€",
  #   :symbol_first        => true,
  #   :subunit             => "Subcent",
  #   :subunit_to_unit     => 10000,
  #   :thousands_separator => ".",
  #   :decimal_mark        => ","
  # }

  # Specify a rounding mode
  # Any one of:
  #
  # BigDecimal::ROUND_UP,
  # BigDecimal::ROUND_DOWN,
  # BigDecimal::ROUND_HALF_UP,
  # BigDecimal::ROUND_HALF_DOWN,
  # BigDecimal::ROUND_HALF_EVEN,
  # BigDecimal::ROUND_CEILING,
  # BigDecimal::ROUND_FLOOR
  #
  # set to BigDecimal::ROUND_HALF_EVEN by default
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Set default.monetize format globally.
  # Default value is nil meaning "ignore this option".
  # Example:

  # config.default_format = {
  #   no_cents_if_whole: false,
  #   symbol: true,
  #   sign_before_symbol: nil
  # }
  config.no_cents_if_whole = false

  # Set default raise_error_on_money_parsing option
  # It will be raise error if assigned different currency
  # The default value is false
  #
  # Example:
  # config.raise_error_on_money_parsing = false
end
