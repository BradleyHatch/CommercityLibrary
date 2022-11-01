# frozen_string_literal: true

C.setup do |config|
  # Core config
  config.price_match = true

  config.cart_name = 'basket'

  config.click_and_collect = false
  config.gift_wrapping = false

  config.click_and_collect_address = "Some Road, RRR RRR"
  
  config.click_and_collect_address_one = "Some Road"
  config.click_and_collect_address_two = "RRRR"
  config.click_and_collect_city = "RRR"
  config.click_and_collect_county = "RR"
  config.click_and_collect_postcode = "RRR RRR"

  config.send_dispatch_notification = true

  config.domain_name = "localhost:3000"

  config.google_review_link = ""

  config.ex_vat = true
  config.ex_vat_threshold = 100

  config.multiple_package_dimensions = true

  config.show_all_variants_in_products_table = false

  config.product_info_fields = {
    arbitrary_field: {
      name: 'Custom Field'
    }
  }

  config.ebay_variant_classifier = "Type"
  config.auto_ebay_sync = true

  config.use_credit = true

  config.validates_shipping_address_phone_number = false

  config.ebay_package_details = %w[weight width height depth]
  config.keep_ebay_stock_in_sync = true

  config.collapse_main_form = true
  config.allow_archive_all_orders = true

  config.manual_delivery = false
  config.send_new_customers_a_voucher_on_order = true
  config.packing_print_off = true

  # Payment config
  config.use_worldpay = false
  config.use_worldpay_bg = true
  config.use_credit = false
  config.use_paymentsense = true
  config.use_sagepay = false
  config.use_barclaycard = true

  config.no_checkout_when_no_stock = true
  config.bypass_cart_link = true
  config.edit_created_at = true

  config.v12_finance = true
  config.deko_finance = true

  config.clear_ebay_item_id = true

  config.three_sixty_image = true

  config.product_conditions = ['New', 'Like New', 'Good', 'Acceptable', 'Mad']

  config.bulk_action_delete  = true

  # Export config
  config.xero_enabled = true
  config.sage_enabled = true

  # eBay Config
  config.delist_when_zero = false
  config.ebay_relist = true
  # config.default_ebay_category = 'DVDs, Films & TV'
  config.default_ebay_category = 'Jewellery & Watches'
  config.default_products_sort = ['featured desc', 'id desc']
  config.ebay_postcode = 'NR32AG'
  config.ebay_additional_details_tab = true

  config.ebay_shipping_service = 'Second Class Standard'
  config.ebay_shipping_international = 'International Economy'
  config.ebay_ship_to_location = 'Europe'

  config.related_product_csv = true
  # config.alt_image_uploader = true

  config.wrap_features_container = '<div class="row seven gs">'
  config.wrap_features_row = '<div class="seven-img g-1">'
  config.wrap_features_end = '</div>'

  config.duplication_slug_attr = "sku"

  config.ebay_body_sub = {

    /(.*menu\W?("|')>)(.*?)><\Wul><\Wdiv>/mi => '',
    /(<div id=\W?("|')footer.*)/mi => '',
    /style=.?("|')width: 896px;?\W?("|')/i => '',
    /<p align=\W?("|')center\W?("|')><br><\Wp>/i => '',
    /<p align=\W?("|')center\W?("|')>&nbsp;<\Wp>/i => '',
    /<p>&nbsp;<\W?p>/i => '',
    /<p align=\W?("|')center\W?("|')><font size=\W?("|')\d\W?("|')><b><br><\Wb><\Wfont><\Wp>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')font-size: \d\d?px\W?\W?("|')><br><\W?p>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')text-align: center\W?\W?("|')><br><\W?p>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')font-size: \d\d?px\W?\W?("|')><strong><font size\W?("|')\d("|')><br><\Wfont><\Wstrong><\Wp>/i => '',
    /<p style=\W?("|')font-size: \d\d?px(.*?)("|') align=\W?("|')center\W?("|')><br><\W?p>/i => '',
    /<p style=\W?("|')font-size\W\s?\d?(\w?|\W)\W\d*(\w*|\W)\W\s\w{4}\W\w{6}\W\s?\w{1,10}\W?("|') align=\W?("|')center\W?("|')>&nbsp;<\Wp>/i => '',
    /<p style=\W?("|')font-size\W?\s\w*\W?\w*\W?("|')\s?\w*\W?("|')\w*("|')>&nbsp;<\Wp>/i => '',
    /<p style=\W?("|')font-size\W?\s\w*\W?\w*\W?("|')\s?\w*\W?("|')\w*("|')><strong>&nbsp;<\Wstrong><\Wp>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')font-size\W?\s\w*\W?\w*\W?\W?("|')><strong>(<br>|&nbsp)<\Wstrong><\Wp>/i => '',
    /<p style=\W?("|')font-size\W?\s?\d?\w?\W?\W?("|')>(<br>|&nbsp)<\Wp>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')text-align: -webkit-center;\W?("|')>(<br>|&nbsp)<\Wp>/i => '',
    /<p align=\W?("|')center\W?("|') style=\W?("|')text-align: -webkit-center;\W?("|')><b style=\W?("|')\w*\W?\w*\W\s?\w*\W\s\w*\W\w*\W\s?\w*\W?\w*\W?\W?">(<br>|&nbsp;)?\s?(<br>|&nbsp;?)<\Wb><\Wp>/ => '',
    /<p align=\W?("|')\w*\W?("|') style=\W?("|')\w*\W?\w*:\s?\w*\W?\w*\W?\W?("|')><strong><font face=\W?("|')\w*\W?("|') size=\W?("|')\d?\W?("|')><span><\W?span><\W?font><\Wstrong>(<br>|&nbsp;)<\Wp>/ => ''

  }

end
