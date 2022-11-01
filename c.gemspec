# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'c/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'c'
  s.version     = C::VERSION
  s.authors     = ['']
  s.email       = ['']
  s.summary     = 'ecommerce engine'
  s.description = 'Commercity is a tool to sync products from platforms like Amazon and Ebay'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = '>= 2.3.0'

  s.add_dependency 'rails', '~> 5.0.3'
  s.add_dependency 'puma'
  s.add_dependency 'redis-rails'
  s.add_dependency 'redis', '3.3.5'
  
  s.add_dependency 'chartkick'
  s.add_dependency 'groupdate'
  s.add_dependency 'repost', '0.3.0'

  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails', '~> 5.0.5'

  s.add_dependency 'haml-rails'
  s.add_dependency 'sass-rails', '~> 5.0'

  s.add_dependency 'money-rails', '1.8.0'
  s.add_dependency 'google_currency'
  # used for rates because google rates doesnt work 
  s.add_dependency 'eu_central_bank'

  s.add_dependency 'devise', '4.5.0'

  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'closure_tree'

  s.add_dependency 'cancancan'

  s.add_dependency 'fog-aws'
  s.add_dependency 'carrierwave'
  s.add_dependency 'mini_magick'

  s.add_dependency 'nokogiri'
  s.add_dependency 'sucker_punch'

  s.add_dependency 'peddler', '1.6.7'
  s.add_dependency 'jeff', '2.0'
  s.add_dependency 'activemerchant', '~> 1.107.3'
  s.add_dependency 'worldpay'
  s.add_dependency 'cd2_tabs'

  s.add_dependency 'deep_cloneable', '~> 2.2.2'
  s.add_dependency 'htmlentities'
  s.add_dependency 'tinymce-rails-imageupload', '4.0.17.beta'
  s.add_dependency 'tinymce-rails', '4.6.7'

  s.add_dependency 'fake_ftp'
  s.add_dependency 'sidekiq'

  s.add_dependency 'ransack'
  s.add_dependency 'pg_search', '~> 2.0.1'
  s.add_dependency 'will_paginate'

  s.add_dependency 'exception_notification'

  # Xero Export
  s.add_dependency 'xeroizer'

  # Excel export
  s.add_dependency 'write_xlsx'

  # Audit trail
  s.add_dependency 'paper_trail', '~> 7.0.2'

  # HTTP Request Library
  # Bit of a mess due to the Deko rush - will sort out later
  s.add_dependency 'httparty'
  s.add_dependency 'rest-client'
  s.add_dependency 'multi_xml' # Included with httparty, but just in case

  # For fixed IP requests
  s.add_dependency 'socksify'

  s.add_dependency 'nested_form_fields'
  s.add_dependency 'select2-rails'
  s.add_dependency 'dropzonejs-rails'

  s.add_dependency 'heroku-deflater'
  ################
end
