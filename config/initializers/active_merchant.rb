# frozen_string_literal: true

ActiveMerchant::Billing::Base.mode = (ENV['PAYPAL_ENVIRONMENT'] || 'test').to_sym
C::EXPRESS_GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(
  login: (ENV['PAYPAL_USERNAME'] || 'PAYPAL_USERNAME'),
  password: (ENV['PAYPAL_PASSWORD'] || 'PAYPAL_PASSWORD'),
  signature: (ENV['PAYPAL_SIGNATURE'] || 'PAYPAL_SIGNATURE')
)
