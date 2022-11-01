# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20211025092454) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "c_addresses", force: :cascade do |t|
    t.integer  "customer_id"
    t.string   "name"
    t.string   "address_one"
    t.string   "address_two"
    t.string   "address_three"
    t.string   "city"
    t.string   "region"
    t.string   "postcode"
    t.integer  "country_id"
    t.string   "phone"
    t.string   "fax"
    t.boolean  "default",       default: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "mobile"
    t.string   "first_name"
    t.string   "last_name"
    t.index ["country_id"], name: "index_c_addresses_on_country_id", using: :btree
    t.index ["customer_id"], name: "index_c_addresses_on_customer_id", using: :btree
  end

  create_table "c_amazon_browse_nodes", force: :cascade do |t|
    t.string   "name"
    t.string   "node_id"
    t.string   "node_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_amazon_browse_nodes_categorizations", force: :cascade do |t|
    t.integer  "amazon_channel_id"
    t.integer  "amazon_browse_node_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["amazon_browse_node_id"], name: "index_abnc_on_amazon_browse_node", using: :btree
    t.index ["amazon_channel_id"], name: "index_abnc_on_amazon_channel", using: :btree
  end

  create_table "c_amazon_categories", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_amazon_processing_queues", force: :cascade do |t|
    t.string   "feed_id"
    t.integer  "feed_type"
    t.integer  "job_status"
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.text     "failure_message"
    t.text     "feed_body"
  end

  create_table "c_amazon_product_attributes", force: :cascade do |t|
    t.integer  "product_type_id"
    t.string   "name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["product_type_id"], name: "index_c_amazon_product_attributes_on_product_type_id", using: :btree
  end

  create_table "c_amazon_product_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "amazon_category_id"
    t.index ["amazon_category_id"], name: "index_c_amazon_product_types_on_amazon_category_id", using: :btree
  end

  create_table "c_apqs_products", force: :cascade do |t|
    t.integer "product_id"
    t.integer "amazon_processing_queue_id"
    t.index ["amazon_processing_queue_id"], name: "index_c_apqs_products_on_amazon_processing_queue_id", using: :btree
    t.index ["product_id"], name: "index_c_apqs_products_on_product_id", using: :btree
  end

  create_table "c_author_records", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "authored_type"
    t.integer  "authored_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["authored_type", "authored_id"], name: "index_c_author_records_on_authored_type_and_authored_id", using: :btree
    t.index ["user_id"], name: "index_c_author_records_on_user_id", using: :btree
  end

  create_table "c_background_jobs", force: :cascade do |t|
    t.string   "name"
    t.datetime "last_ran"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "message"
    t.integer  "job_size"
    t.integer  "job_processed_count"
    t.integer  "status",              default: 0, null: false
  end

  create_table "c_blogs", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "url_alias"
    t.text     "preview_body"
    t.index ["created_at"], name: "index_c_blogs_on_created_at", using: :btree
  end

  create_table "c_brands", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.string   "internal_id"
    t.string   "url"
    t.string   "image"
    t.boolean  "manufacturer"
    t.boolean  "supplier"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "featured",     default: false
    t.string   "slug"
    t.boolean  "in_menu",      default: false
  end

  create_table "c_bundle_items", force: :cascade do |t|
    t.integer  "bundled_variant_id"
    t.integer  "variant_id"
    t.integer  "web_price_pennies",     default: 0,     null: false
    t.string   "web_price_currency",    default: "GBP", null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "quantity"
    t.integer  "ebay_price_pennies",    default: 0,     null: false
    t.string   "ebay_price_currency",   default: "GBP", null: false
    t.integer  "amazon_price_pennies",  default: 0,     null: false
    t.string   "amazon_price_currency", default: "GBP", null: false
    t.index ["bundled_variant_id"], name: "index_c_bundle_items_on_bundled_variant_id", using: :btree
    t.index ["variant_id"], name: "index_c_bundle_items_on_variant_id", using: :btree
  end

  create_table "c_cart_item_notes", force: :cascade do |t|
    t.integer  "cart_item_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["cart_item_id"], name: "index_c_cart_item_notes_on_cart_item_id", using: :btree
  end

  create_table "c_cart_item_option_variants", force: :cascade do |t|
    t.integer  "price_id"
    t.integer  "cart_item_id"
    t.integer  "option_variant_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["cart_item_id"], name: "index_c_cart_item_option_variants_on_cart_item_id", using: :btree
    t.index ["option_variant_id"], name: "index_c_cart_item_option_variants_on_option_variant_id", using: :btree
    t.index ["price_id"], name: "index_c_cart_item_option_variants_on_price_id", using: :btree
  end

  create_table "c_cart_items", force: :cascade do |t|
    t.integer  "quantity",      default: 0
    t.integer  "variant_id"
    t.integer  "cart_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "voucher_id"
    t.boolean  "gift_wrapping", default: false, null: false
    t.index ["cart_id"], name: "index_c_cart_items_on_cart_id", using: :btree
    t.index ["variant_id"], name: "index_c_cart_items_on_variant_id", using: :btree
    t.index ["voucher_id"], name: "index_c_cart_items_on_voucher_id", using: :btree
  end

  create_table "c_carts", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "order_id"
    t.boolean  "anonymous",                       default: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "item_digest"
    t.integer  "previous_country_id"
    t.boolean  "accepted_privacy_policy"
    t.boolean  "country_didnt_match_from_paypal", default: false
    t.boolean  "abandoned_mailout_three_day",     default: false
    t.boolean  "abandoned_mailout_five_day",      default: false
    t.boolean  "abandoned_mailout_seven_day",     default: false
    t.string   "email"
    t.boolean  "prefer_click_and_collect",        default: false, null: false
    t.index ["customer_id"], name: "index_c_carts_on_customer_id", using: :btree
    t.index ["order_id"], name: "index_c_carts_on_order_id", using: :btree
  end

  create_table "c_categories", force: :cascade do |t|
    t.string   "name"
    t.string   "internal_id"
    t.string   "displayed_name"
    t.text     "body"
    t.string   "image"
    t.integer  "parent_id"
    t.integer  "weight"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "featured",               default: false
    t.string   "banner_url"
    t.string   "alt_tag"
    t.string   "slug"
    t.boolean  "in_menu",                default: false
    t.integer  "amazon_product_type_id"
    t.integer  "ebay_category_id"
    t.integer  "template_group_id"
    t.string   "image_alt"
    t.string   "ebay_store_category_id"
    t.integer  "google_category_id"
    t.index ["amazon_product_type_id"], name: "index_c_categories_on_amazon_product_type_id", using: :btree
    t.index ["parent_id"], name: "index_c_categories_on_parent_id", using: :btree
  end

  create_table "c_category_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "category_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "category_desc_idx", using: :btree
  end

  create_table "c_category_property_keys", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "property_key_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["category_id"], name: "index_c_category_property_keys_on_category_id", using: :btree
    t.index ["property_key_id"], name: "index_c_category_property_keys_on_property_key_id", using: :btree
  end

  create_table "c_collection_categories", force: :cascade do |t|
    t.integer  "collection_id"
    t.integer  "category_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["category_id"], name: "index_c_collection_categories_on_category_id", using: :btree
    t.index ["collection_id"], name: "index_c_collection_categories_on_collection_id", using: :btree
  end

  create_table "c_collection_variants", force: :cascade do |t|
    t.integer  "collection_id"
    t.integer  "variant_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["collection_id"], name: "index_c_collection_variants_on_collection_id", using: :btree
    t.index ["variant_id"], name: "index_c_collection_variants_on_variant_id", using: :btree
  end

  create_table "c_collections", force: :cascade do |t|
    t.string   "name"
    t.string   "image"
    t.string   "slug"
    t.text     "body"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "image_alt"
    t.integer  "collection_type", default: 0
  end

  create_table "c_content_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "content_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "content_desc_idx", using: :btree
  end

  create_table "c_contents", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.integer  "content_type"
    t.string   "template"
    t.text     "summary"
    t.integer  "parent_id"
    t.integer  "weight"
    t.string   "slug"
    t.boolean  "published",         default: true
    t.boolean  "protected",         default: false
    t.boolean  "featured",          default: false
    t.boolean  "home",              default: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "template_group_id"
    t.index ["created_by_id"], name: "index_c_contents_on_created_by_id", using: :btree
    t.index ["parent_id"], name: "index_c_contents_on_parent_id", using: :btree
    t.index ["updated_by_id"], name: "index_c_contents_on_updated_by_id", using: :btree
  end

  create_table "c_countries", force: :cascade do |t|
    t.string   "name"
    t.string   "iso2"
    t.string   "iso3"
    t.string   "tld"
    t.string   "currency"
    t.boolean  "eu",                   default: false
    t.boolean  "active",               default: true
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "zone_id"
    t.string   "numeric",    limit: 3, default: "000", null: false
  end

  create_table "c_custom_fields", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_custom_values", force: :cascade do |t|
    t.string   "value"
    t.integer  "custom_field_id"
    t.string   "custom_recordable_type"
    t.integer  "custom_recordable_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["custom_recordable_type", "custom_recordable_id"], name: "custom_field_index", using: :btree
  end

  create_table "c_customer_accounts", force: :cascade do |t|
    t.string   "email",                   default: "", null: false
    t.string   "encrypted_password",      default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "payment_type",            default: 0,  null: false
    t.integer  "account_type",            default: 0,  null: false
    t.boolean  "accepted_privacy_policy"
    t.index ["email"], name: "index_c_customer_accounts_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_c_customer_accounts_on_reset_password_token", unique: true, using: :btree
  end

  create_table "c_customers", force: :cascade do |t|
    t.string   "email",                 default: "",    null: false
    t.datetime "remember_created_at"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "name"
    t.string   "company"
    t.string   "phone"
    t.string   "mobile"
    t.string   "fax"
    t.string   "thumbnail"
    t.integer  "channel"
    t.string   "amazon_email"
    t.boolean  "sparse",                default: false
    t.integer  "customer_account_id"
    t.string   "sage_ref"
    t.boolean  "consent_order",         default: false
    t.boolean  "consent_promotion",     default: false
    t.boolean  "consent_products",      default: false
    t.boolean  "consent_contact_post",  default: false
    t.boolean  "consent_contact_phone", default: false
    t.boolean  "consent_contact_email", default: false
    t.index ["customer_account_id"], name: "index_c_customers_on_customer_account_id", using: :btree
    t.index ["email"], name: "index_c_customers_on_email", using: :btree
  end

  create_table "c_data_transfers", force: :cascade do |t|
    t.string   "name"
    t.string   "file"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "import_type"
    t.datetime "import_finished_at"
    t.datetime "import_started_at"
    t.datetime "import_at"
    t.boolean  "replace_images",     default: false, null: false
  end

  create_table "c_delivery_providers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "tracking_link", default: ""
  end

  create_table "c_delivery_rule_gaps", force: :cascade do |t|
    t.integer  "rule_id"
    t.decimal  "lower_bound", default: "0.0"
    t.decimal  "cost"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["rule_id"], name: "index_c_delivery_rule_gaps_on_rule_id", using: :btree
  end

  create_table "c_delivery_rules", force: :cascade do |t|
    t.integer  "service_id"
    t.integer  "zone_id"
    t.decimal  "base_price"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "max_cart_price_pennies"
    t.string   "max_cart_price_currency", default: "GBP", null: false
    t.integer  "min_cart_price_pennies",  default: 0,     null: false
    t.string   "min_cart_price_currency", default: "GBP", null: false
    t.index ["service_id"], name: "index_c_delivery_rules_on_service_id", using: :btree
  end

  create_table "c_delivery_service_prices", force: :cascade do |t|
    t.decimal  "min_weight"
    t.decimal  "max_weight"
    t.text     "country_ids"
    t.integer  "price_pennies",           default: 0,     null: false
    t.string   "price_currency",          default: "GBP", null: false
    t.integer  "delivery_service_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "max_cart_price_pennies"
    t.string   "max_cart_price_currency", default: "GBP", null: false
    t.integer  "min_cart_price_pennies",  default: 0,     null: false
    t.string   "min_cart_price_currency", default: "GBP", null: false
    t.index ["delivery_service_id"], name: "index_c_delivery_service_prices_on_delivery_service_id", using: :btree
  end

  create_table "c_delivery_service_providers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_delivery_service_variants", force: :cascade do |t|
    t.integer  "variant_id"
    t.integer  "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_c_delivery_service_variants_on_service_id", using: :btree
    t.index ["variant_id"], name: "index_c_delivery_service_variants_on_variant_id", using: :btree
  end

  create_table "c_delivery_services", force: :cascade do |t|
    t.string   "name"
    t.integer  "provider_id"
    t.integer  "channel"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "ebay_alias"
    t.string   "display_name"
    t.decimal  "tax_rate",          default: "20.0", null: false
    t.boolean  "click_and_collect", default: false
    t.index ["provider_id"], name: "index_c_delivery_services_on_provider_id", using: :btree
  end

  create_table "c_delivery_services_old", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.boolean  "active"
    t.boolean  "default"
    t.integer  "delivery_service_provider_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "ebay_alias"
    t.index ["delivery_service_provider_id"], name: "index_c_delivery_services_old_on_delivery_service_provider_id", using: :btree
  end

  create_table "c_documents", force: :cascade do |t|
    t.string   "name"
    t.string   "document"
    t.string   "documentable_type"
    t.integer  "documentable_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "c_ebay_categories", force: :cascade do |t|
    t.boolean  "best_offer_enabled"
    t.boolean  "auto_pay_enabled"
    t.integer  "category_id"
    t.integer  "category_level"
    t.string   "category_name"
    t.integer  "category_parent_id"
    t.integer  "parent_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "c_ebay_category_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "ebay_category_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "ebay_category_desc_idx", using: :btree
  end

  create_table "c_ebayauths", force: :cascade do |t|
    t.text     "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_enquiries", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.text     "body"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "phone_number"
    t.boolean  "google_prompt", default: false
  end

  create_table "c_google_categories", force: :cascade do |t|
    t.string   "name"
    t.text     "full_path"
    t.string   "category_id"
    t.string   "category_parent_name"
    t.integer  "parent_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "c_google_category_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "google_category_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "google_category_desc_idx", using: :btree
  end

  create_table "c_images", force: :cascade do |t|
    t.string   "image"
    t.string   "alt"
    t.string   "caption"
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.boolean  "featured_image", default: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "preview_image",  default: false
  end

  create_table "c_menu_item_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "menu_item_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "menu_item_desc_idx", using: :btree
  end

  create_table "c_menu_items", force: :cascade do |t|
    t.string   "name"
    t.string   "link"
    t.boolean  "visible",      default: true
    t.integer  "parent_id"
    t.integer  "weight"
    t.string   "machine_name"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "target"
    t.integer  "content_id"
    t.index ["content_id"], name: "index_c_menu_items_on_content_id", using: :btree
  end

  create_table "c_messages", force: :cascade do |t|
    t.string   "subject"
    t.text     "body"
    t.boolean  "read",       default: false
    t.boolean  "replied",    default: false
    t.integer  "source"
    t.string   "sender_id"
    t.string   "message_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "c_non_deletes", force: :cascade do |t|
    t.boolean  "deleted",            default: false
    t.string   "non_deletable_type"
    t.integer  "non_deletable_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["non_deletable_type", "non_deletable_id"], name: "index_c_non_deletes_on_non_deletable_type_and_non_deletable_id", using: :btree
  end

  create_table "c_notification_emails", force: :cascade do |t|
    t.string   "email",      default: "",    null: false
    t.boolean  "orders",     default: false
    t.boolean  "enquiries",  default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "c_notifications", force: :cascade do |t|
    t.string   "notifiable_type"
    t.integer  "notifiable_id"
    t.boolean  "read",            default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_c_notifications_on_notifiable_type_and_notifiable_id", using: :btree
  end

  create_table "c_order_amazon_orders", force: :cascade do |t|
    t.string   "amazon_id"
    t.string   "buyer_name"
    t.string   "buyer_email"
    t.string   "selected_shipping"
    t.date     "earliest_delivery_date"
    t.date     "latest_delivery_date"
    t.text     "body"
    t.integer  "order_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["order_id"], name: "index_c_order_amazon_orders_on_order_id", using: :btree
  end

  create_table "c_order_deliveries", force: :cascade do |t|
    t.string   "name"
    t.integer  "price_pennies",             default: 0,      null: false
    t.string   "price_currency",            default: "GBP",  null: false
    t.datetime "processing_at"
    t.datetime "shipped_at"
    t.integer  "delivery_service_price_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "overridden",                default: false
    t.integer  "delivery_service_id"
    t.decimal  "tax_rate",                  default: "20.0", null: false
    t.boolean  "terms_carriage_charges",    default: false,  null: false
    t.boolean  "terms_additional_charges",  default: false,  null: false
    t.index ["delivery_service_price_id"], name: "index_c_order_deliveries_on_delivery_service_price_id", using: :btree
  end

  create_table "c_order_ebay_orders", force: :cascade do |t|
    t.string   "ebay_order_id"
    t.string   "buyer_username"
    t.string   "buyer_email"
    t.text     "transaction_id"
    t.string   "gateway_transaction_id"
    t.text     "body"
    t.integer  "order_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "ebay_delivery_service"
    t.boolean  "seller_protection",      default: false
    t.string   "sales_record_id"
    t.text     "checkout_message"
    t.index ["order_id"], name: "index_c_order_ebay_orders_on_order_id", using: :btree
  end

  create_table "c_order_items", force: :cascade do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.string   "name"
    t.integer  "price_pennies",           default: 0,     null: false
    t.string   "price_currency",          default: "GBP", null: false
    t.integer  "quantity",                default: 0
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.decimal  "tax_rate"
    t.string   "sku"
    t.string   "ebay_order_line_item_id"
    t.text     "description"
    t.string   "ebay_sku"
    t.integer  "voucher_id"
    t.boolean  "gift_wrapping",           default: false, null: false
    t.integer  "cart_item_id"
    t.index ["cart_item_id"], name: "index_c_order_items_on_cart_item_id", using: :btree
    t.index ["order_id"], name: "index_c_order_items_on_order_id", using: :btree
    t.index ["product_id"], name: "index_c_order_items_on_product_id", using: :btree
    t.index ["voucher_id"], name: "index_c_order_items_on_voucher_id", using: :btree
  end

  create_table "c_order_notes", force: :cascade do |t|
    t.string   "note"
    t.integer  "order_id"
    t.integer  "user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "created_by_id"
    t.index ["created_by_id"], name: "index_c_order_notes_on_created_by_id", using: :btree
    t.index ["order_id"], name: "index_c_order_notes_on_order_id", using: :btree
    t.index ["user_id"], name: "index_c_order_notes_on_user_id", using: :btree
  end

  create_table "c_order_payments", force: :cascade do |t|
    t.integer  "amount_paid_pennies",  default: 0,     null: false
    t.string   "amount_paid_currency", default: "GBP", null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "payable_type"
    t.integer  "payable_id"
    t.index ["payable_type", "payable_id"], name: "index_c_order_payments_on_payable_type_and_payable_id", using: :btree
  end

  create_table "c_order_sales", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "shipping_address_id"
    t.integer  "billing_address_id"
    t.integer  "delivery_id"
    t.integer  "payment_id"
    t.integer  "status",              default: 5
    t.integer  "channel",             default: 0
    t.integer  "flag",                default: 0
    t.text     "checkout_notes"
    t.datetime "recieved_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "ebay_order_id"
    t.boolean  "printed",             default: false
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.text     "channel_hash"
    t.json     "body"
    t.uuid     "access_token"
    t.integer  "export_status"
    t.text     "export_error_log"
    t.jsonb    "info",                default: {},    null: false
    t.boolean  "processed",           default: false
    t.integer  "voucher_id"
    t.boolean  "voucher_email_sent",  default: false
    t.boolean  "tracking_email_sent", default: false
    t.datetime "dispatched_at"
    t.integer  "transaction_suffix",  default: 0,     null: false
    t.index ["billing_address_id"], name: "index_c_order_sales_on_billing_address_id", using: :btree
    t.index ["customer_id"], name: "index_c_order_sales_on_customer_id", using: :btree
    t.index ["delivery_id"], name: "index_c_order_sales_on_delivery_id", using: :btree
    t.index ["payment_id"], name: "index_c_order_sales_on_payment_id", using: :btree
    t.index ["shipping_address_id"], name: "index_c_order_sales_on_shipping_address_id", using: :btree
  end

  create_table "c_order_trackings", force: :cascade do |t|
    t.string   "provider"
    t.string   "number"
    t.integer  "delivery_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "c_page_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id",   null: false
    t.integer "descendant_id", null: false
    t.integer "generations",   null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "page_anc_desc_idx", unique: true, using: :btree
    t.index ["descendant_id"], name: "page_desc_idx", using: :btree
  end

  create_table "c_page_infos", force: :cascade do |t|
    t.string   "title"
    t.text     "meta_description"
    t.string   "url_alias"
    t.boolean  "published",        default: true
    t.boolean  "protected",        default: false
    t.string   "page_type"
    t.integer  "page_id"
    t.boolean  "home_page",        default: false
    t.integer  "order"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.index ["page_type", "page_id"], name: "index_c_page_infos_on_page_type_and_page_id", using: :btree
    t.index ["url_alias"], name: "index_c_page_infos_on_url_alias", using: :btree
  end

  create_table "c_pages", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.string   "layout"
    t.boolean  "in_menu"
    t.string   "menu_item"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "url_alias"
    t.text     "preview_body"
    t.integer  "parent_id"
    t.integer  "weight"
  end

  create_table "c_payment_method_credits", force: :cascade do |t|
    t.string   "ip"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_payment_method_deko_finances", force: :cascade do |t|
    t.string   "ip"
    t.string   "deko_id"
    t.string   "unique_reference",             null: false
    t.integer  "last_status",      default: 0, null: false
    t.jsonb    "csn"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["unique_reference"], name: "index_c_payment_method_deko_finances_on_unique_reference", unique: true, using: :btree
  end

  create_table "c_payment_method_manuals", force: :cascade do |t|
    t.string   "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_payment_method_payment_senses", force: :cascade do |t|
    t.string   "ip"
    t.string   "cross_reference"
    t.string   "request_string"
    t.string   "response_string"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "transaction_id"
  end

  create_table "c_payment_method_paypal_expresses", force: :cascade do |t|
    t.string   "payer_id"
    t.string   "ip"
    t.string   "payment_token"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "c_payment_method_pro_formas", force: :cascade do |t|
    t.string   "ip"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_payment_method_sagepays", force: :cascade do |t|
    t.string   "ip"
    t.string   "card_identifier"
    t.string   "merchant_session_key"
    t.string   "transaction_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "threed_secure_status"
  end

  create_table "c_payment_method_v12_finances", force: :cascade do |t|
    t.string   "ip"
    t.string   "application_id"
    t.string   "application_guid"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "last_status",      default: 0
  end

  create_table "c_payment_method_worldpay_business_gateways", force: :cascade do |t|
    t.string   "ip"
    t.string   "transaction_id"
    t.json     "response_body"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "c_payment_method_worldpay_cardsaves", force: :cascade do |t|
    t.string   "ip"
    t.string   "cross_reference"
    t.string   "request_string"
    t.string   "response_string"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "c_payment_method_worldpays", force: :cascade do |t|
    t.string   "ip"
    t.string   "payment_token"
    t.string   "order_code"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "c_permission_subjects", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.string   "subject_type"
    t.integer  "subject_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "c_permissions", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "permission_subject_id"
    t.boolean  "read"
    t.boolean  "new"
    t.boolean  "edit"
    t.boolean  "remove"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["permission_subject_id"], name: "index_c_permissions_on_permission_subject_id", using: :btree
    t.index ["role_id"], name: "index_c_permissions_on_role_id", using: :btree
  end

  create_table "c_price_changes", force: :cascade do |t|
    t.integer  "without_tax_pennies",      default: 0,     null: false
    t.string   "without_tax_currency",     default: "GBP", null: false
    t.integer  "with_tax_pennies",         default: 0,     null: false
    t.string   "with_tax_currency",        default: "GBP", null: false
    t.decimal  "tax_rate"
    t.integer  "was_without_tax_pennies",  default: 0,     null: false
    t.string   "was_without_tax_currency", default: "GBP", null: false
    t.integer  "was_with_tax_pennies",     default: 0,     null: false
    t.string   "was_with_tax_currency",    default: "GBP", null: false
    t.decimal  "was_tax_rate"
    t.string   "reason"
    t.integer  "user_id"
    t.integer  "price_id"
    t.datetime "changed_at"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.index ["price_id"], name: "index_c_price_changes_on_price_id", using: :btree
    t.index ["user_id"], name: "index_c_price_changes_on_user_id", using: :btree
  end

  create_table "c_prices", force: :cascade do |t|
    t.integer  "without_tax_pennies",  default: 0,      null: false
    t.string   "without_tax_currency", default: "GBP",  null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "with_tax_pennies",     default: 0,      null: false
    t.string   "with_tax_currency",    default: "GBP",  null: false
    t.decimal  "tax_rate",             default: "20.0"
    t.boolean  "override",             default: false
  end

  create_table "c_product_add_on_products", force: :cascade do |t|
    t.integer  "main_id"
    t.integer  "add_on_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["add_on_id"], name: "index_c_product_add_on_products_on_add_on_id", using: :btree
    t.index ["main_id"], name: "index_c_product_add_on_products_on_main_id", using: :btree
  end

  create_table "c_product_answers", force: :cascade do |t|
    t.integer  "question_id"
    t.text     "body"
    t.boolean  "sent",        default: false
    t.boolean  "external",    default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["question_id"], name: "index_c_product_answers_on_question_id", using: :btree
  end

  create_table "c_product_barcodes", force: :cascade do |t|
    t.string   "value",      null: false
    t.integer  "symbology",  null: false
    t.integer  "variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["variant_id"], name: "index_c_product_barcodes_on_variant_id", using: :btree
  end

  create_table "c_product_brand_vouchers", force: :cascade do |t|
    t.integer  "brand_id"
    t.integer  "voucher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_c_product_brand_vouchers_on_brand_id", using: :btree
    t.index ["voucher_id"], name: "index_c_product_brand_vouchers_on_voucher_id", using: :btree
  end

  create_table "c_product_categorizations", force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "category_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_c_product_categorizations_on_category_id", using: :btree
    t.index ["product_id"], name: "index_c_product_categorizations_on_product_id", using: :btree
  end

  create_table "c_product_category_vouchers", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "voucher_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_c_product_category_vouchers_on_category_id", using: :btree
    t.index ["voucher_id"], name: "index_c_product_category_vouchers_on_voucher_id", using: :btree
  end

  create_table "c_product_channel_amazon_bullet_points", force: :cascade do |t|
    t.string   "value"
    t.integer  "product_channel_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["product_channel_id"], name: "index_amzn_bullet_points_on_product_channel_id", using: :btree
  end

  create_table "c_product_channel_amazon_search_terms", force: :cascade do |t|
    t.string   "term"
    t.integer  "product_channel_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["product_channel_id"], name: "index_amzn_search_terms_on_product_channel_id", using: :btree
  end

  create_table "c_product_channel_amazons", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "name"
    t.text     "recommended_browse_nodes"
    t.text     "description"
    t.text     "features"
    t.text     "key_product_features"
    t.text     "condition_note"
    t.integer  "current_price_pennies",    default: 0,     null: false
    t.string   "current_price_currency",   default: "GBP", null: false
    t.integer  "de_price_pennies",         default: 0,     null: false
    t.string   "de_price_currency",        default: "GBP", null: false
    t.integer  "es_price_pennies",         default: 0,     null: false
    t.string   "es_price_currency",        default: "GBP", null: false
    t.integer  "fr_price_pennies",         default: 0,     null: false
    t.string   "fr_price_currency",        default: "GBP", null: false
    t.integer  "it_price_pennies",         default: 0,     null: false
    t.string   "it_price_currency",        default: "GBP", null: false
    t.integer  "shipping_cost_pennies",    default: 0,     null: false
    t.string   "shipping_cost_currency",   default: "GBP", null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "product_type_id"
    t.integer  "amazon_category_id"
    t.boolean  "last_push_success"
    t.json     "last_push_body"
    t.string   "ebc_logo"
    t.string   "ebc_description"
    t.string   "ebc_module1_heading"
    t.string   "ebc_module1_body"
    t.string   "ebc_module2_heading"
    t.string   "ebc_module2_sub_heading"
    t.string   "ebc_module2_body"
    t.string   "ebc_module2_image"
    t.index ["amazon_category_id"], name: "index_c_product_channel_amazons_on_amazon_category_id", using: :btree
    t.index ["master_id"], name: "index_c_product_channel_amazons_on_master_id", using: :btree
    t.index ["product_type_id"], name: "index_c_product_channel_amazons_on_product_type_id", using: :btree
  end

  create_table "c_product_channel_ebay_feature_images", force: :cascade do |t|
    t.integer  "ebay_id"
    t.integer  "image_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ebay_id"], name: "index_c_product_channel_ebay_feature_images_on_ebay_id", using: :btree
    t.index ["image_id"], name: "index_c_product_channel_ebay_feature_images_on_image_id", using: :btree
  end

  create_table "c_product_channel_ebay_ship_to_locations", force: :cascade do |t|
    t.integer  "ebay_id"
    t.integer  "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ebay_id"], name: "index_c_product_channel_ebay_ship_to_locations_on_ebay_id", using: :btree
  end

  create_table "c_product_channel_ebay_shipping_services", force: :cascade do |t|
    t.integer  "ebay_id"
    t.integer  "delivery_service_id"
    t.boolean  "international",            default: false
    t.integer  "cost_pennies",             default: 0,     null: false
    t.string   "cost_currency",            default: "GBP", null: false
    t.integer  "additional_cost_pennies",  default: 0,     null: false
    t.string   "additional_cost_currency", default: "GBP", null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "ship_time_max"
    t.integer  "ship_time_min"
    t.boolean  "expedited",                default: false
  end

  create_table "c_product_channel_ebays", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "name"
    t.string   "sub_title"
    t.integer  "ebay_category_id"
    t.text     "description"
    t.boolean  "ended",                              default: false
    t.integer  "condition"
    t.string   "condition_description"
    t.string   "country"
    t.integer  "dispatch_time"
    t.string   "duration"
    t.integer  "start_price_pennies",                default: 0,     null: false
    t.string   "start_price_currency",               default: "GBP", null: false
    t.boolean  "payment_method_paypal"
    t.boolean  "payment_method_postal"
    t.boolean  "payment_method_cheque"
    t.boolean  "payment_method_other"
    t.boolean  "payment_method_cc"
    t.boolean  "payment_method_escrow"
    t.string   "postcode"
    t.string   "domestic_shipping_type"
    t.boolean  "pickup_in_store"
    t.boolean  "click_collect_collection_available"
    t.boolean  "returns_accepted"
    t.string   "restocking_fee_value_option"
    t.string   "returns_description"
    t.string   "refund_option"
    t.string   "returns_within"
    t.string   "returns_cost_paid_by"
    t.boolean  "warranty_offered"
    t.string   "warranty_duration"
    t.string   "warranty_type"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "sold",                               default: false
    t.text     "shop_wrap"
    t.datetime "last_sync_time"
    t.boolean  "global_shipping",                    default: false
    t.boolean  "payment_method_money_order",         default: false
    t.boolean  "no_shipping_options",                default: false
    t.text     "wrap_text_1"
    t.text     "wrap_text_2"
    t.integer  "max_stock",                          default: 0
    t.boolean  "uses_ebay_catalogue",                default: false
    t.string   "package_type"
    t.integer  "classifier_property_key_id"
    t.index ["classifier_property_key_id"], name: "index_c_product_channel_ebays_on_classifier_property_key_id", using: :btree
    t.index ["ebay_category_id"], name: "index_c_product_channel_ebays_on_ebay_category_id", using: :btree
    t.index ["master_id"], name: "index_c_product_channel_ebays_on_master_id", using: :btree
  end

  create_table "c_product_channel_images", force: :cascade do |t|
    t.string   "channel_type"
    t.integer  "channel_id"
    t.integer  "image_id"
    t.string   "name"
    t.integer  "order"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["channel_type", "channel_id"], name: "index_c_product_channel_images_on_channel_type_and_channel_id", using: :btree
    t.index ["image_id"], name: "index_c_product_channel_images_on_image_id", using: :btree
  end

  create_table "c_product_channel_webs", force: :cascade do |t|
    t.integer  "master_id"
    t.string   "name"
    t.text     "description"
    t.text     "features"
    t.text     "specification"
    t.integer  "current_price_pennies"
    t.string   "current_price_currency",  default: "GBP", null: false
    t.integer  "discount_price_pennies"
    t.string   "discount_price_currency", default: "GBP", null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "subtitle"
    t.string   "sub_title"
    t.index ["master_id"], name: "index_c_product_channel_webs_on_master_id", using: :btree
  end

  create_table "c_product_dropdown_categories", force: :cascade do |t|
    t.integer  "dropdown_id"
    t.integer  "category_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["category_id"], name: "index_c_product_dropdown_categories_on_category_id", using: :btree
    t.index ["dropdown_id"], name: "index_c_product_dropdown_categories_on_dropdown_id", using: :btree
  end

  create_table "c_product_dropdown_options", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "dropdown_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["dropdown_id"], name: "index_c_product_dropdown_options_on_dropdown_id", using: :btree
  end

  create_table "c_product_dropdown_variants", force: :cascade do |t|
    t.integer  "dropdown_id"
    t.integer  "variant_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["dropdown_id"], name: "index_c_product_dropdown_variants_on_dropdown_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_dropdown_variants_on_variant_id", using: :btree
  end

  create_table "c_product_dropdowns", force: :cascade do |t|
    t.string   "name"
    t.boolean  "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_product_features", force: :cascade do |t|
    t.string   "name"
    t.string   "image"
    t.text     "body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "feature_type"
    t.string   "link"
  end

  create_table "c_product_images", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "variant_id"
    t.string   "image"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "alt",        default: ""
    t.index ["master_id"], name: "index_c_product_images_on_master_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_images_on_variant_id", using: :btree
  end

  create_table "c_product_masters", force: :cascade do |t|
    t.integer  "brand_id"
    t.integer  "manufacturer_id"
    t.integer  "condition"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.decimal  "tax_rate",          default: "20.0"
    t.jsonb    "ebay_local_errors", default: []
    t.index ["brand_id"], name: "index_c_product_masters_on_brand_id", using: :btree
  end

  create_table "c_product_offers", force: :cascade do |t|
    t.integer  "variant_id"
    t.integer  "price_pennies",  default: 0,     null: false
    t.string   "price_currency", default: "GBP", null: false
    t.integer  "quantity"
    t.string   "sender_email"
    t.integer  "status"
    t.integer  "source"
    t.string   "sender_id"
    t.string   "offer_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["variant_id"], name: "index_c_product_offers_on_variant_id", using: :btree
  end

  create_table "c_product_option_variants", force: :cascade do |t|
    t.integer  "option_id"
    t.integer  "variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_id"], name: "index_c_product_option_variants_on_option_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_option_variants_on_variant_id", using: :btree
  end

  create_table "c_product_options", force: :cascade do |t|
    t.string   "name"
    t.integer  "price_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "compulsory", default: false
    t.index ["price_id"], name: "index_c_product_options_on_price_id", using: :btree
  end

  create_table "c_product_price_matches", force: :cascade do |t|
    t.integer  "competitor"
    t.integer  "variant_id"
    t.string   "url"
    t.integer  "price_pennies",  default: 0,     null: false
    t.string   "price_currency", default: "GBP", null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["variant_id"], name: "index_c_product_price_matches_on_variant_id", using: :btree
  end

  create_table "c_product_product_features", force: :cascade do |t|
    t.integer  "variant_id"
    t.integer  "feature_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id"], name: "index_c_product_product_features_on_feature_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_product_features_on_variant_id", using: :btree
  end

  create_table "c_product_product_relations", force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "related_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "related_id"], name: "index_c_product_product_relations_on_product_id_and_related_id", unique: true, using: :btree
    t.index ["product_id"], name: "index_c_product_product_relations_on_product_id", using: :btree
    t.index ["related_id"], name: "index_c_product_product_relations_on_related_id", using: :btree
  end

  create_table "c_product_property_keys", force: :cascade do |t|
    t.string   "key"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "display",    default: true
    t.integer  "weight",     default: 0
  end

  create_table "c_product_property_values", force: :cascade do |t|
    t.string   "value"
    t.integer  "property_key_id"
    t.integer  "variant_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "active",          default: true
    t.index ["property_key_id", "value", "variant_id"], name: "property_value_validation_index", unique: true, using: :btree
    t.index ["property_key_id"], name: "index_c_product_property_values_on_property_key_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_property_values_on_variant_id", using: :btree
  end

  create_table "c_product_questions", force: :cascade do |t|
    t.integer  "variant_id"
    t.string   "subject"
    t.text     "body"
    t.integer  "source"
    t.string   "sender_id"
    t.string   "sender_email"
    t.string   "message_id"
    t.boolean  "answered"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["message_id"], name: "index_c_product_questions_on_message_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_questions_on_variant_id", using: :btree
  end

  create_table "c_product_reservations", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.integer  "product_variant_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "reference"
  end

  create_table "c_product_variant_dimensions", force: :cascade do |t|
    t.decimal  "weight",         default: "0.0"
    t.string   "weight_unit",    default: "KG"
    t.decimal  "x_dimension",    default: "0.0"
    t.decimal  "y_dimension",    default: "0.0"
    t.decimal  "z_dimension",    default: "0.0"
    t.string   "dimension_unit", default: "M"
    t.integer  "variant_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "notes",          default: ""
    t.index ["variant_id"], name: "index_c_product_variant_dimensions_on_variant_id", using: :btree
  end

  create_table "c_product_variant_images", force: :cascade do |t|
    t.integer  "variant_id"
    t.integer  "image_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_c_product_variant_images_on_image_id", using: :btree
    t.index ["variant_id"], name: "index_c_product_variant_images_on_variant_id", using: :btree
  end

  create_table "c_product_variant_vouchers", force: :cascade do |t|
    t.integer  "voucher_id"
    t.integer  "variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["variant_id"], name: "index_c_product_variant_vouchers_on_variant_id", using: :btree
    t.index ["voucher_id"], name: "index_c_product_variant_vouchers_on_voucher_id", using: :btree
  end

  create_table "c_product_variants", force: :cascade do |t|
    t.integer  "master_id"
    t.integer  "country_of_manufacture_id"
    t.string   "name"
    t.text     "description"
    t.string   "sku"
    t.string   "asin"
    t.string   "mpn"
    t.integer  "cost_price_pennies",             default: 0,     null: false
    t.string   "cost_price_currency",            default: "GBP", null: false
    t.integer  "rrp_pennies",                    default: 0,     null: false
    t.string   "rrp_currency",                   default: "GBP", null: false
    t.decimal  "weight",                         default: "0.0"
    t.string   "weight_unit",                    default: "KG"
    t.decimal  "x_dimension",                    default: "0.0"
    t.decimal  "y_dimension",                    default: "0.0"
    t.decimal  "z_dimension",                    default: "0.0"
    t.string   "dimension_unit",                 default: "M"
    t.integer  "current_stock",                  default: 0
    t.integer  "package_quantity",               default: 1
    t.boolean  "discontinued",                   default: false
    t.boolean  "published",                      default: true
    t.boolean  "published_web",                  default: true
    t.boolean  "published_ebay",                 default: false
    t.boolean  "published_amazon",               default: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.boolean  "featured",                       default: false
    t.integer  "status",                         default: 0
    t.string   "slug"
    t.integer  "product_tag",                    default: 1
    t.integer  "delivery_override_pennies",      default: 0,     null: false
    t.string   "delivery_override_currency",     default: "GBP", null: false
    t.boolean  "sticky",                         default: false
    t.integer  "web_price_id"
    t.integer  "amazon_price_id"
    t.integer  "ebay_price_id"
    t.integer  "retail_price_id"
    t.string   "manufacturer_product_url"
    t.boolean  "main_variant"
    t.boolean  "has_been_pushed_to_amazon",      default: false
    t.boolean  "has_been_pushed_to_ebay",        default: false
    t.string   "item_id"
    t.json     "ebay_last_push_body"
    t.boolean  "ebay_last_push_success"
    t.boolean  "has_delivery_override",          default: false
    t.string   "oe_number"
    t.integer  "cache_web_price_pennies",        default: 0,     null: false
    t.string   "cache_web_price_currency",       default: "GBP", null: false
    t.integer  "cache_ebay_price_pennies",       default: 0,     null: false
    t.string   "cache_ebay_price_currency",      default: "GBP", null: false
    t.integer  "cache_amazon_price_pennies",     default: 0,     null: false
    t.string   "cache_amazon_price_currency",    default: "GBP", null: false
    t.integer  "cache_image_id"
    t.boolean  "bundle",                         default: false
    t.jsonb    "info",                           default: {},    null: false
    t.string   "ebay_sku"
    t.boolean  "display_in_lists",               default: true
    t.text     "import_dump"
    t.integer  "image_variant_id"
    t.boolean  "no_barcodes",                    default: false
    t.boolean  "published_google",               default: false
    t.boolean  "three_sixty_image",              default: false
    t.integer  "order",                          default: 0
    t.boolean  "manually_disabled",              default: false
    t.boolean  "display_only",                   default: false
    t.datetime "myriad_updated_at"
    t.string   "amazon_product_pipeline_id"
    t.string   "ebay_product_pipeline_id"
    t.jsonb    "amazon_product_pipeline_data",   default: {}
    t.boolean  "should_push_to_amazon_pipeline", default: false
    t.jsonb    "ebay_product_pipeline_data",     default: {}
    t.boolean  "build_from_ebay",                default: false
    t.boolean  "click_and_collect",              default: false
    t.index ["amazon_price_id"], name: "index_c_product_variants_on_amazon_price_id", using: :btree
    t.index ["amazon_product_pipeline_id"], name: "index_c_product_variants_on_amazon_product_pipeline_id", unique: true, using: :btree
    t.index ["cache_image_id"], name: "index_c_product_variants_on_cache_image_id", using: :btree
    t.index ["country_of_manufacture_id"], name: "index_c_product_variants_on_country_of_manufacture_id", using: :btree
    t.index ["ebay_price_id"], name: "index_c_product_variants_on_ebay_price_id", using: :btree
    t.index ["master_id"], name: "index_c_product_variants_on_master_id", using: :btree
    t.index ["retail_price_id"], name: "index_c_product_variants_on_retail_price_id", using: :btree
    t.index ["sku"], name: "index_c_product_variants_on_sku", unique: true, using: :btree
    t.index ["web_price_id"], name: "index_c_product_variants_on_web_price_id", using: :btree
  end

  create_table "c_product_vouchers", force: :cascade do |t|
    t.string   "name"
    t.string   "code",                                         null: false
    t.boolean  "restricted",                   default: false
    t.decimal  "discount_multiplier",          default: "1.0"
    t.integer  "flat_discount_pennies",        default: 0,     null: false
    t.string   "flat_discount_currency",       default: "GBP", null: false
    t.integer  "per_item_discount_pennies",    default: 0,     null: false
    t.string   "per_item_discount_currency",   default: "GBP", null: false
    t.integer  "minimum_cart_value_pennies",   default: 0,     null: false
    t.string   "minimum_cart_value_currency",  default: "GBP", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.boolean  "active",                       default: true
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "restricted_brand",             default: false, null: false
    t.decimal  "per_item_discount_multiplier", default: "1.0"
    t.integer  "uses",                         default: 0
    t.integer  "times_used",                   default: 0
    t.boolean  "restricted_category",          default: false, null: false
    t.index ["code"], name: "index_c_product_vouchers_on_code", using: :btree
  end

  create_table "c_product_wraps", force: :cascade do |t|
    t.string   "name"
    t.text     "wrap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_projects", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.string   "url_alias"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_redirects", force: :cascade do |t|
    t.string   "old_url"
    t.string   "new_url"
    t.datetime "last_used"
    t.integer  "used_counter", default: 0
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "c_roles", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_sales_highlights", force: :cascade do |t|
    t.string   "image"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "color"
  end

  create_table "c_setting_groups", force: :cascade do |t|
    t.string   "name"
    t.string   "machine_name"
    t.text     "body"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "c_setting_type_booleans", force: :cascade do |t|
    t.boolean  "value"
    t.boolean  "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_setting_type_images", force: :cascade do |t|
    t.string   "value"
    t.string   "default"
    t.string   "default_string"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "c_setting_type_strings", force: :cascade do |t|
    t.string   "value"
    t.string   "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_setting_type_texts", force: :cascade do |t|
    t.string   "value"
    t.string   "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_settings", force: :cascade do |t|
    t.string   "key"
    t.string   "data_type"
    t.integer  "data_id"
    t.integer  "setting_group_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["data_id", "data_type"], name: "index_c_settings_on_data_id_and_data_type", unique: true, using: :btree
    t.index ["data_type", "data_id"], name: "index_c_settings_on_data_type_and_data_id", using: :btree
    t.index ["key"], name: "index_c_settings_on_key", unique: true, using: :btree
    t.index ["setting_group_id"], name: "index_c_settings_on_setting_group_id", using: :btree
  end

  create_table "c_slides", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "image"
    t.integer  "slideshow_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.text     "body"
    t.index ["slideshow_id"], name: "index_c_slides_on_slideshow_id", using: :btree
  end

  create_table "c_slideshows", force: :cascade do |t|
    t.string   "name"
    t.string   "machine_name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.text     "body"
  end

  create_table "c_team_members", force: :cascade do |t|
    t.string   "name"
    t.string   "role"
    t.string   "image"
    t.text     "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_template_blocks", force: :cascade do |t|
    t.string   "name"
    t.text     "body"
    t.string   "image"
    t.string   "url"
    t.integer  "size"
    t.integer  "kind_of"
    t.integer  "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_template_groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "c_template_regions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "group_id"
  end

  create_table "c_testimonials", force: :cascade do |t|
    t.text     "quote"
    t.string   "author"
    t.integer  "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "title"
    t.integer  "content_id"
    t.index ["content_id"], name: "index_c_testimonials_on_content_id", using: :btree
  end

  create_table "c_user_roles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_c_user_roles_on_role_id", using: :btree
    t.index ["user_id"], name: "index_c_user_roles_on_user_id", using: :btree
  end

  create_table "c_users", force: :cascade do |t|
    t.string   "name"
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "cd2admin",               default: false
    t.index ["email"], name: "index_c_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_c_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "c_weights", force: :cascade do |t|
    t.integer  "value"
    t.string   "orderable_type"
    t.integer  "orderable_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["orderable_type", "orderable_id"], name: "index_c_weights_on_orderable_type_and_orderable_id", using: :btree
  end

  create_table "c_wishlist_items", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "variant_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "c_zones", force: :cascade do |t|
    t.string "name"
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
    t.index ["version_id"], name: "index_version_associations_on_version_id", using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.jsonb    "object"
    t.jsonb    "object_changes"
    t.datetime "created_at"
    t.integer  "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
    t.index ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree
  end

  add_foreign_key "c_cart_item_option_variants", "c_cart_items", column: "cart_item_id"
  add_foreign_key "c_cart_item_option_variants", "c_prices", column: "price_id"
  add_foreign_key "c_cart_item_option_variants", "c_product_option_variants", column: "option_variant_id"
  add_foreign_key "c_cart_items", "c_product_vouchers", column: "voucher_id"
  add_foreign_key "c_carts", "c_customers", column: "customer_id"
  add_foreign_key "c_categories", "c_categories", column: "parent_id", on_delete: :nullify
  add_foreign_key "c_menu_items", "c_menu_items", column: "parent_id", on_delete: :nullify
  add_foreign_key "c_order_items", "c_product_vouchers", column: "voucher_id"
  add_foreign_key "c_product_answers", "c_product_questions", column: "question_id"
  add_foreign_key "c_product_brand_vouchers", "c_brands", column: "brand_id"
  add_foreign_key "c_product_brand_vouchers", "c_product_vouchers", column: "voucher_id"
  add_foreign_key "c_product_category_vouchers", "c_categories", column: "category_id"
  add_foreign_key "c_product_category_vouchers", "c_product_vouchers", column: "voucher_id"
  add_foreign_key "c_product_channel_amazons", "c_product_masters", column: "master_id", on_delete: :restrict
  add_foreign_key "c_product_channel_ebays", "c_product_masters", column: "master_id", on_delete: :restrict
  add_foreign_key "c_product_channel_images", "c_product_images", column: "image_id", on_delete: :nullify
  add_foreign_key "c_product_channel_webs", "c_product_masters", column: "master_id", on_delete: :restrict
  add_foreign_key "c_product_images", "c_product_masters", column: "master_id", on_delete: :cascade
  add_foreign_key "c_product_images", "c_product_variants", column: "variant_id", on_delete: :nullify
  add_foreign_key "c_product_masters", "c_brands", column: "brand_id", on_delete: :nullify
  add_foreign_key "c_product_offers", "c_product_variants", column: "variant_id"
  add_foreign_key "c_product_option_variants", "c_product_options", column: "option_id"
  add_foreign_key "c_product_option_variants", "c_product_variants", column: "variant_id"
  add_foreign_key "c_product_options", "c_prices", column: "price_id"
  add_foreign_key "c_product_questions", "c_product_variants", column: "variant_id"
  add_foreign_key "c_product_variant_vouchers", "c_product_variants", column: "variant_id"
  add_foreign_key "c_product_variant_vouchers", "c_product_vouchers", column: "voucher_id"
  add_foreign_key "c_product_variants", "c_countries", column: "country_of_manufacture_id", on_delete: :restrict
  add_foreign_key "c_product_variants", "c_product_masters", column: "master_id", on_delete: :cascade
end
