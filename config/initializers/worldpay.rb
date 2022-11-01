# frozen_string_literal: true

require 'worldpay'

C::WORLDPAY_API = nil
if C.use_worldpay
  # Ensure both keys are available on startup, otherwise results could be
  # silently catastrophic.
  server_key = ENV.fetch('WORLDPAY_SERVER_KEY')
  client_key = ENV.fetch('WORLDPAY_CLIENT_KEY')
  raise if server_key.blank? || client_key.blank?
  C::WORLDPAY_API = Worldpay.new(server_key)
end
