# frozen_string_literal: true

require 'sagepay_api'

C::SAGEPAY_API = SagepayAPI.new(
  ENV['SAGEPAY_KEY'],
  ENV['SAGEPAY_PASSWORD'],
  ENV['SAGEPAY_VENDOR'],
  environment: ENV['SAGEPAY_ENV']
)
