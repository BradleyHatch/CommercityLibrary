# rubocop:disable all
# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.4.1'

gemspec

gem 'figaro'
gem 'pg', '0.18.4'
gem 'ebay-trader', git: 'https://github.com/CD2/ebay_trader.git'
gem 'mailchimp-api'
gem 'eu_central_bank'
gem 'repost', '0.3.0'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rack-mini-profiler', require: false#
  gem 'shoulda'
  gem 'rspec'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'selenium-webdriver', '3.4.0'
  gem 'brakeman', :require => false
  gem 'haml-lint', require: false
  gem 'rails_best_practices'
  gem 'reek'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'capybara-screenshot'
  gem 'aws-sdk'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'simplecov'
end
