# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w[c/placeholder_product_image.png]
Rails.application.config.assets.precompile += %w[c/print_application.css]
Rails.application.config.assets.precompile += %w[c/ckeditor/config.js.erb]
Rails.application.config.assets.precompile += %w[c/logo.svg]
Rails.application.config.assets.precompile += %w( c/dz-loading.svg )
Rails.application.config.assets.precompile += %w[c/shop_logo.png]
Rails.application.config.assets.precompile += %w[c/ckeditor/amazon_config.js]
Rails.application.config.assets.precompile += %w[c/dz-loading.svg]

# Rails.application.config.assets.paths << "#{Rails.root}/app/assets/sample"
Rails.application.config.assets.precompile += %w[import_test.csv]
Rails.application.config.assets.precompile += %w[download_test.csv]
Rails.application.config.assets.precompile += %w[c/paymentsense.jpg]
Rails.application.config.assets.precompile += %w[c/deko_cool.svg]
