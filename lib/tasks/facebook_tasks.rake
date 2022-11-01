
client_id = ''
client_secret = ''

def build_fb_feed
  C::Product::Variant.where(status: :active)
end

namespace :c do
  namespace :facebook do

    require 'net/http'

    task test: :environment do
      url = "https://graph.facebook.com/oauth/access_token?client_id=#{client_id}&client_secret=#{client_secret}&grant_type=client_credentials"
      response = Net::HTTP.get(URI.parse(url))

      parsed_response = JSON.parse(response)

      access_token = parsed_response["access_token"]
    end
  end
end