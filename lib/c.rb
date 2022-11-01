# frozen_string_literal: true

require 'rubygems'
require 'fog/aws'

Gem.loaded_specs['c'].dependencies.each do |d|
  require d.name unless ['fog-aws', 'google_currency'].include?(d.name)
end

require 'money/bank/google_currency'
require 'c/engine'

module C
  class << self
    mattr_accessor :store_name
    self.store_name = 'Name'

    mattr_accessor :domain_name
    self.domain_name = 'example.com'
    
    mattr_accessor :email_from
    self.domain_name = 'notifications@mailer.com'

    mattr_accessor :cart_name
    self.cart_name = 'cart'

    mattr_accessor :dev_site_url
    self.dev_site_url = 'http://example.com'

    mattr_accessor :prod_site_url
    self.prod_site_url = 'http://example.com'

    mattr_accessor :email, :enquiries_email, :errors_email, :order_notification_email
    self.email                    = 'email@example.com'
    self.enquiries_email          = 'email@example.com'
    self.errors_email             = 'email@example.com'
    self.order_notification_email = ['recipient@example.com']

    mattr_accessor :click_and_collect
    self.click_and_collect = false
    
    mattr_accessor :click_and_collect_address
    self.click_and_collect_address = ""

    mattr_accessor :click_and_collect_address_one
    self.click_and_collect_address_one = ""
    mattr_accessor :click_and_collect_address_two
    self.click_and_collect_address_two = ""
    mattr_accessor :click_and_collect_city
    self.click_and_collect_city = ""
    mattr_accessor :click_and_collect_postcode
    self.click_and_collect_postcode = ""
    mattr_accessor :click_and_collect_county
    self.click_and_collect_county = ""

    mattr_accessor :gift_wrapping
    self.gift_wrapping = false

    mattr_accessor :sales_index_per_page
    self.sales_index_per_page = 15
    
    mattr_accessor :show_all_variants_in_products_table
    self.show_all_variants_in_products_table = false

    mattr_accessor :validates_shipping_address_phone_number
    self.validates_shipping_address_phone_number = false

    mattr_accessor :multiple_package_dimensions
    self.multiple_package_dimensions = false

    mattr_accessor :ebay_variant_classifier
    self.ebay_variant_classifier = nil

    mattr_accessor :out_of_stock_report_email
    self.out_of_stock_report_email = nil

    mattr_accessor :keep_ebay_stock_in_sync
    self.keep_ebay_stock_in_sync = nil

    mattr_accessor :send_dispatch_notification
    self.send_dispatch_notification = false

    mattr_accessor :show_vouchers_on_cart
    self.show_vouchers_on_cart = true

    mattr_accessor :vouchers_to_notify_on_use_ids
    self.vouchers_to_notify_on_use_ids = nil

    mattr_accessor :notify_voucher_used_email
    self.notify_voucher_used_email = nil

    mattr_accessor :external_logo_url
    self.external_logo_url = 'https://via.placeholder.com/64x64'

    mattr_accessor :external_logo_width
    self.external_logo_width = '43'

    mattr_accessor :primary_color
    self.primary_color = '#5C5C5C'

    mattr_accessor :admin_mount
    self.admin_mount = 'admin'

    mattr_accessor :cart_mount
    self.cart_mount = 'cart'

    mattr_accessor :account_mount
    self.account_mount = 'account'

    mattr_accessor :ebay_paypal
    self.ebay_paypal = 'example@paypal.com'

    mattr_accessor :commerce
    self.commerce = true

    mattr_accessor :price_match
    self.price_match = false

    mattr_accessor :google_review_link
    self.google_review_link = ""

    mattr_accessor :content_sections
    self.content_sections = %i[basic_page service project blog location]

    # used in checkout process to prevent checkout when chosen quantity is greater than current_stock
    mattr_accessor :no_checkout_when_no_stock
    self.no_checkout_when_no_stock = false

    mattr_accessor :bypass_cart_link
    self.bypass_cart_link = false

    mattr_accessor :add_to_cart_quantity
    self.add_to_cart_quantity = false

    mattr_accessor :hide_cart_tax
    self.hide_cart_tax = false

    # used when printing off an invoice to hide values so it can act as a packing slip
    mattr_accessor :packing_print_off
    self.packing_print_off = false

    mattr_accessor :send_new_customers_a_voucher_on_order
    self.send_new_customers_a_voucher_on_order = false

    # Either :with_tax or :without_tax (see Price model)
    mattr_accessor :default_tax
    self.default_tax = :with_tax

    mattr_accessor :allow_archive_all_orders
    self.allow_archive_all_orders = false

    mattr_accessor :hide_zero_stock_products
    self.hide_zero_stock_products = false

    mattr_accessor :show_all_in_search
    self.show_all_in_search = false

    mattr_accessor :show_product_csv_reports
    self.show_product_csv_reports = false

    mattr_accessor :strip_html_on_csv_export
    self.show_product_csv_reports = false

    # specify channel name to display first channel image on index tables
    mattr_accessor :display_thumbnail
    self.display_thumbnail = nil

    mattr_accessor :edit_created_at
    self.edit_created_at = false

    mattr_accessor :alt_image_uploader
    self.alt_image_uploader = false

    mattr_accessor :import_properties_upcase
    self.import_properties_upcase = true

    # add default values of more config vars here
    mattr_accessor :default_published_web
    self.default_published_web = false

    mattr_accessor :default_display_in_lists
    self.default_display_in_lists = true

    # ability to toggle collapse main product fields
    mattr_accessor :collapse_main_form
    self.collapse_main_form = false

    # enable checkbox for toggling 360 images for products
    mattr_accessor :three_sixty_image
    self.three_sixty_image = false

    mattr_accessor :product_index_search_fields
    self.product_index_search_fields = ['SKU', 'Name', 'MPN']

    mattr_accessor :product_index_search_all_variants
    self.product_index_search_all_variants = false

    mattr_accessor :product_conditions
    self.product_conditions = ['New', 'Like New', 'Good', 'Acceptable']

    mattr_accessor :default_products_sort
    self.default_products_sort = 'id desc'

    mattr_accessor :bulk_action_delete
    self.bulk_action_delete = false

    # secondary sorting for front end pages e.g. winchmax masters index
    # is ordered by ebay price desc but category frontend pages need to be
    # ordered by web price desc
    mattr_accessor :default_category_products_sort
    self.default_category_products_sort = nil

    # used to determine per page for pagination on admin indexes
    mattr_accessor :products_per_page
    self.products_per_page = 25

    # used to determine per page on front end pages
    mattr_accessor :products_per_category_page
    self.products_per_category_page = 12

    # links for per page
    mattr_accessor :per_page_links
    self.per_page_links = [24, 36, 90]

    # ebay wrap thingz
    mattr_accessor :wrap_features_container
    self.wrap_features_container = ''

    mattr_accessor :wrap_features_row
    self.wrap_features_row = ''

    mattr_accessor :wrap_features_end
    self.wrap_features_end = ''

    mattr_accessor :clear_ebay_item_id
    self.clear_ebay_item_id = false

    # ebay defaults
    mattr_accessor :ebay_start_price
    self.ebay_start_price = :web_price

    mattr_accessor :ebay_additional_details_tab
    self.ebay_additional_details_tab = false

    mattr_accessor :default_ebay_category
    self.default_ebay_category = nil

    mattr_accessor :ebay_duration
    self.ebay_duration = 'GTC'

    mattr_accessor :ebay_payment_paypal
    self.ebay_payment_paypal = true

    mattr_accessor :ebay_relist
    self.ebay_relist = false

    # possible values can in array can be weight / depth / height / width
    mattr_accessor :ebay_package_details
    self.ebay_package_details = ["weight"]

    mattr_accessor :v12_finance
    self.v12_finance = false

    mattr_accessor :deko_finance
    self.deko_finance = false

    mattr_accessor :deko_finance_max_deposit_pc
    self.deko_finance_max_deposit_pc = 50

    mattr_accessor :deko_finance_min_deposit_pc
    self.deko_finance_min_deposit_pc = 10

    mattr_accessor :use_paypal
    self.use_paypal = true

    mattr_accessor :use_sagepay
    self.use_sagepay = false

    mattr_accessor :use_worldpay
    self.use_worldpay = false

    mattr_accessor :use_worldpay_bg
    self.use_worldpay_bg = false

    mattr_accessor :use_worldpay_cardsave
    self.use_worldpay_cardsave = false

    mattr_accessor :use_barclaycard
    self.use_barclaycard = false

    mattr_accessor :use_paymentsense
    self.use_paymentsense = false

    mattr_accessor :use_credit
    self.use_credit = false

    mattr_accessor :build_ebay_store_categories
    self.build_ebay_store_categories = false

    mattr_accessor :ebay_postcode
    self.ebay_postcode = nil

    mattr_accessor :ebay_dispatch_days
    self.ebay_dispatch_days = 3

    mattr_accessor :ebay_shipping_type
    self.ebay_shipping_type = 'Flat'

    mattr_accessor :ebay_shipping_service
    self.ebay_shipping_service = ''

    mattr_accessor :ebay_shipping_international
    self.ebay_shipping_international = ''

    mattr_accessor :ebay_ship_to_location
    self.ebay_ship_to_location = ''

    mattr_accessor :no_site
    self.no_site = false

    mattr_accessor :ebay_ignore_gsp_fees
    self.ebay_ignore_gsp_fees = false

    mattr_accessor :ebay_shipping_cost
    self.ebay_shipping_cost = 0

    mattr_accessor :ebay_shipping_additional_cost
    self.ebay_shipping_additional_cost = 0

    mattr_accessor :ebay_shipping_free
    self.ebay_shipping_free = false

    mattr_accessor :ebay_shipping_collect
    self.ebay_shipping_collect = false

    mattr_accessor :ebay_returns_accepted
    self.ebay_returns_accepted = true

    mattr_accessor :ebay_body_sub
    self.ebay_body_sub = {}

    mattr_accessor :ebay_sku_from_body
    self.ebay_sku_from_body = false

    mattr_accessor :ebay_status_sync
    self.ebay_status_sync = false

    mattr_accessor :auto_ebay_sync
    self.auto_ebay_sync = false

    mattr_accessor :order_export_ebay_sku_asc
    self.order_export_ebay_sku_asc = false

    mattr_accessor :order_export_per_month
    self.order_export_per_month = false

    mattr_accessor :manual_delivery
    self.manual_delivery = false

    mattr_accessor :flat_delivery_rate
    self.flat_delivery_rate = true

    mattr_accessor :combined_delivery_rate
    self.combined_delivery_rate = false

    mattr_accessor :fallback_to_any_delivery_when_no_rule
    self.fallback_to_any_delivery_when_no_rule = true

    mattr_accessor :delivery_override_only_for_zones
    self.delivery_override_only_for_zones = false

    mattr_accessor :delist_when_zero
    self.delist_when_zero = false

    mattr_accessor :recaptcha
    self.recaptcha = false

    mattr_accessor :xero_enabled
    self.xero_enabled = false

    mattr_accessor :sage_enabled
    self.sage_enabled = false

    mattr_accessor :ex_vat
    self.ex_vat = false

    mattr_accessor :duplication_slug_attr
    self.duplication_slug_attr = "name"

    mattr_accessor :ex_vat_threshold
    self.ex_vat_threshold = 0

    mattr_accessor :can_select_many_product_options
    self.can_select_many_product_options = true

    mattr_accessor :variant_property_key_concat
    self.variant_property_key_concat = ''

    mattr_accessor :order_info_fields
    self.order_info_fields = {}

    mattr_accessor :product_info_fields
    self.product_info_fields = {
      ## Example field config:
      # field_name: {
      #   # Human-friendly name
      #   name: 'Special order',
      #   # Current handled types are currently only :boolean. Don't include if
      #   # it's anything else
      #   type: :boolean,
      #   # Help text to be displayed below the field
      #   help: 'Only allow this product to be ordered specially'
      # }
    }

    mattr_accessor :related_product_csv
    self.related_product_csv = false

    mattr_accessor :invoice_print_copies
    self.invoice_print_copies = 1

    # Must always have at least one type of account. The first is always the
    # default.
    mattr_accessor :customer_account_types
    self.customer_account_types = %i[general]

    mattr_accessor :master_tabs
    self.master_tabs = {
      web: :web,
      amazon: :amazon,
      ebay: :ebay,
      variants: :variants,
      bundle: :bundle,
      properties: :properties,
      images: :images,
      docs: :docs,
      price_match: :price_match,
      options: :options,
      questions: :questions,
      price_changes: :price_changes,
    }

    mattr_accessor :periodic_task_list
    self.periodic_task_list = [
      ### Orders
      ## Fetch eBay orders
      # 'c:ebay:get_orders',

      ## Get Amazon orders. Only use one of the following two tasks.
      ## Fetch orders from the UK marketplace
      # 'c:amazon:get_orders',
      # Fetch orders from the UK, DE, ES, FR, IT marketplace
      # 'c:amazon:get_international_orders',

      ### Finance
      # Fetch updates on V12 payments
      # 'c:v12:get_payments',

      ### Inventory
      ## Upload stock numbers to all Amazon products
      # 'c:amazon:update_inventory',
      ## Upload stock numbers to all eBay products
      # 'c:ebay:mass_stock_update',

      ### Product Updates
      ## Deal with processing requests to Amazon
      # 'c:amazon:check_processing_queue',
      ## Push products that need updating to Amazon
      # 'c:amazon:push_updated_products',
      ## Remove Amazon processing queue records to prevent DB from becoming
      ## bloated
      # 'c:amazon:prune_processing_queues',

      ### Price Comparison
      ## Retreive price matches
      # 'c:check_price_matches',

      ### Offers
      ## Retreive eBay best offers
      # 'c:ebay:get_offers'

      ### Questions
      ## Retreive eBay product questions
      # 'c:ebay:pull_questions'

      ### Messages
      ## Retreive eBay messages
      # 'c:ebay:pull_messages'
      # 'c:ebay:get_messages'
    ]

    def setup(*)
      # this function maps the vars from your app into your engine
      yield self
    end

    # returns the current store's domain name with an explicit 'http(s)://' and no trailing '/'
    def absolute_root
      root = C.domain_name.to_s.downcase
      unless root.starts_with?('http', '//', 'www')
        root = (Rails.env.production? ? 'https://www.' : 'http://www.') + root
      end
      root.chomp('/')
    end

    # given a relative path, returns an absolute url
    def absolute_url(path)
      path = path.to_s.downcase
      return path if path.starts_with?('http', '//', 'www')
      absolute_root + '/' + path.gsub(%r{\A\.?/}, '')
    end
  end
end
