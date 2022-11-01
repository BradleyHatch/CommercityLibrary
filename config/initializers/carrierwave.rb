# frozen_string_literal: true

CarrierWave.configure do |config|
  if !Rails.env.development?
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV['S3_ACCESS_KEY'],
      aws_secret_access_key: ENV['S3_SECRET_KEY'],
      region: 'eu-west-1'
    }
    config.fog_directory = ENV['S3_BUCKET']
    config.cache_dir = Rails.root.join('tmp', 'uploads')
    config.fog_attributes = { 'Cache-Control' => 'max-age=315576000',
                              'Expires' => 1.week.from_now.httpdate }
    config.storage :fog
  else
    config.storage :file
  end
end
