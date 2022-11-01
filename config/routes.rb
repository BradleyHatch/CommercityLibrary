# frozen_string_literal: true

C::Engine.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  post '/tinymce_assets', to: 'admin/images#create'

  get '/admin', to: 'admin/dashboards#index'

  get '/admin/debug', to: 'admin#debug'
  post '/admin/no_images_csv', to: 'admin#no_images_csv'
  post '/admin/no_desc_csv', to: 'admin#no_desc_csv'
  post '/admin/all_weights_csv', to: 'admin#all_weights_csv'
  post '/admin/active_weights_csv', to: 'admin#active_weights_csv'

  post '/admin/save_price_change_reason', to: 'admin#save_price_change_reason'

  scope module: :admin, path: C.admin_mount do
    # to build channel scope routes
    channels = %w[amazon ebay web manual]

    root 'dashboards#index'
    post 'dashboards/list', to: 'dashboards#list'

    get '/sage', to: 'admin#sage'


    devise_for :users, class_name: 'C::User', module: 'c/admin/devise'

    resources :users, except: [:show] do
      get :confirm_destroy, on: :member
      collection do
        resources :roles, except: [:show] do
          member do
            get :confirm_destroy
          end
        end
      end
    end

    resources :notification_emails, except: [:show] do
      get :confirm_destroy, on: :member
    end

    resources :testimonials, except: [:show] do
      collection do
        post :sort
        patch :update_order
      end
      member do
        get :confirm_destroy
      end
    end

    resources :contents, except: :show do
      collection { C.content_sections.each { |cont| get cont } }
      member do
        get :confirm_destroy
        post :dropzone_image
        post :reload_images
        post :destroy_image
        post :set_preview_image
        post :set_featured_image
      end
    end

    scope module: :templates, as: :template do
      resources :groups do
        collection do
          post :sort
        end
        resources :regions, as: 'template_regions' do
          collection do
            post :sort
          end
          resources :blocks, except: [:show], as: 'template_blocks' do
            collection do
              post :sort
            end
          end
        end
      end

      resources :blocks, except: [:new, :create, :edit, :update, :destroy], as: 'template_blocks' do
        member do
          post :dropzone_image
          post :reload_images
          post :destroy_image
          post :set_preview_image
          post :set_featured_image
        end
      end
    end

    resources :team_members, except: [:show] do
      collection do
        post :sort
      end
      member do
        get :confirm_destroy
      end
    end

    scope module: :products, as: :product do
      resources :masters, path: 'products', except: [:show] do
        collection do
          get :cached_search_redirect
          get :price_match

          post :bulk_actions
          get :mass_assign
          post :mass_assign_update
          get :assign_property_values
          post :assign_property_values_update

          get :merge
          post :merge_update

          get :create_from_ebay
          post :create_from_ebay

          get :amazon_autocomplete
          get :amazon_product_types

          get :property_values_autocomplete
        end
        member do
          get :remote_show

          post :create_channel_image
          post :destroy_channel_image

          post :product_image
          post :reload_images
          post :destroy_image

          get :ebay_methods
          get :ebay_category
          get :ebay_confirm
          get :ebay_auto_sync
          get :render_ebay_wrap
          get :clear_ebay_item_id

          post :toggle_ebay_feature_block
          post :toggle_ebay_feature_image
          post :sort_product_features
          post :sort_feature_images
          post :reload_toggle

          post :save_price_match
          post :save_best_price_match
          post :update_price_matches

          post :amazon_methods
          post :toggle_amazon_published

          post :split_buttons

          get :new_duplicate
          post :create_duplicate
        end
        get :confirm_destroy, on: :member
        resources :variants, path: 'variants', as: :product_variants do
          member do
            post :assign_image
            post :unassign_image

            get :new_duplicate
            post :create_duplicate
          end
          resources :images, only: :destroy do
            collection do
              post :sort
            end
          end

          get :confirm_destroy, on: :member
          scope module: :channels do
            resource :amazon, only: %i[show edit update], as: :product_channel_amazon
            resource :ebay, only: %i[show edit update], as: :product_channel_ebay
            resource :web, only: %i[show edit update], as: :product_channel_web
          end
        end
      end
      resources :vouchers, only: %i[index new edit create update destroy] do
        member do
          get :confirm_destroy
        end
      end
      resources :property_keys, only: %i[index new create edit update destroy] do
        member do
          get :confirm_destroy
        end
      end
      resources :features, only: %i[index new create edit update]
      resources :variants, only: :show
      resources :wraps, only: %i[index new create edit update destroy] do
        member do
          get :render_ebay_wrap
        end
      end
      resources :questions, only: %i[index show destroy] do
        member do
          post :reply
        end
      end
      resources :offers, only: %i[index]
      resources :options, only: %i[index new create edit update destroy]
      resources :dropdowns, only: %i[index new create edit update destroy] do
        resources :dropdown_options, as: :product_dropdown_options, only: %i[new
          edit create update destroy]
      end
    end

    resources :data_transfers do
      member do
        get :confirm_destroy
        post :csv_import
        get :confirm_import
        post :data_confirm_import
      end
    end

    resources :documents, only: %i[index new create edit update destroy] do
      collection do
        post :bulk_upload
      end
    end

    resources :amazon_processing_queues, only: %i[index show] do
      collection do
        get :latest_product
        get :all
      end
    end

    scope module: :orders, as: :order do
      resources :sales, except: %i[edit destroy] do
        member do
          post :archive
          get :confirm_archive
          get :toggle_flag
          get :xero_export
          
          get :new_dispatch_order
          patch :update_dispatch_order

          get :new_pro_forma_paid_order
          patch :update_pro_forma_paid_order
        end
        collection do
          %i[awaiting_payment awaiting_dispatch dispatched cancelled archived all pending flagged carts].each { |r| get r }
          post :bulk_actions
          get :bulk_xero_export
          get :print
          get :mass_print
          get :stats
          get :stats
          post :spreadsheet_item_list_export
          post :sage_orders
          post :sage_results
          get :google_review_prompt
          post :send_google_review_prompt
        end
        get :print
        resources :addresses, except: %i[index show]
        resources :items, except: %i[index show], as: :order_items do
          member do
            get :confirm_destroy
          end
        end
      end
    end

    resources :brands, except: [:show] do
      member do
        get :confirm_destroy
      end
      collection do
        post :bulk_actions
      end
    end

    namespace :delivery do
      resources :providers do
        member do
          get :confirm_destroy
        end
      end
      resources :services do
        member do
          get :confirm_destroy
        end
        post :sort, on: :collection, defaults: { format: 'xml' }
        resources :rules, only: %i[edit update destroy create]
      end
      resources :rules, only: [] do
        member do
          get :confirm_destroy
        end
      end
    end

    resources :customers do
      collection do
        post :bulk_actions
        get :confirm_mass_destroy
        post :mass_destroy
        get :companies
        channels.each { |ch| get ch }
      end
      member do
        get :confirm_destroy
      end
      resources :addresses, except: %i[index show]
    end

    resources :custom_fields, except: :show do
      member do
        get :confirm_destroy
      end
    end

    resources :menu_items, except: [:show] do
      collection do
        patch :update_order
      end
      member do
        get :confirm_destroy
      end
    end

    resources :categories, except: [:show] do
      collection do
        patch :update_order
      end
      member do
        get :confirm_destroy
        get :remove_image

        get :ebay_category
      end
    end

    resources :collections, except: [:show] do
      member do
        get :confirm_destroy
        get :remove_image
      end
    end

    resources :redirects, except: :show do
      post :bulk_actions, on: :collection
      member do
        get :confirm_destroy
      end
    end

    resources :sales_highlights, except: :show do
      collection do
        post :sort
      end
      member do
        get :confirm_destroy
      end
    end

    resources :setting_groups, only: %i[index show], path: 'settings' do
      resources :settings, only: %i[edit update destroy], shallow: true do
        get :confirm_destroy, on: :member
      end
    end

    resources :countries, only: %i[index edit update] do
      member do
        get :toggle_state
        get :confirm_destroy
      end
    end

    resources :ebayauths, only: %i[index] do
      collection do
        post :new_auth
        get :success
        get :fail
      end
    end

    resources :enquiries, only: %i[show index destroy] do
      get :confirm_destroy, on: :member
    end

    resources :notifications, only: %i[show index destroy], path: 'customer-contact' do
      member do
        get :render_message
      end
    end

    resources :product_reservations, only: %i[index destroy] do
      get :confirm_destroy, on: :member
    end

    resources :slideshows, only: %i[new create index edit update] do
      resources :slides, only: %i[new edit create update destroy] do
        collection do
          post :sort
        end
        member do
          get :confirm_destroy
        end
      end
      member do
        get :confirm_destroy
      end
    end

    resources :barcodes, except: :show, as: 'product_barcodes' do
      get :confirm_destroy, on: :member
      get :upload_import, on: :collection
      post :csv_import, on: :collection
    end

    resources :addresses, only: :destroy do
      get :confirm_destroy, on: :member
    end

    resources :xero_sessions, only: [:new] do
      get :create, on: :collection
      get :destroy, path: 'destroy', on: :collection
    end
  end # END OF ADMIN SCOPE

  scope module: 'front', path: C.cart_mount do
    post 'mailchimp/subscribe'

    resource :checkout, only: %i[new create destroy], path_names: { new: '' } do
      collection do
        delete :cancel

        get :account, action: :get_account
        patch :account

        get :address, action: :get_address
        get :new_address, action: :new_address
        patch :create_address, action: :create_address
        patch :address

        get :delivery, action: :get_delivery
        post :delivery

        get :payment, action: :get_payment
        patch :payment
        get :express_payment
        get :express_payment_return
        get :express_payment_cancel

        post :world_pay_payment

        post :v12_payment

        post :deko_payment

        post :sagepay_payment
        get :sagepay_session_key

        get :sagepay_3dsf_redirect
        post :sagepay_3dsf_return

        get :sagepay_3dsc_redirect
        post :sagepay_3dsc_return

        post :payment_sense_payment
        post :payment_sense_return

        post :worldpay_cardsave_payment
        post :worldpay_cardsave_return

        post :worldpay_bg_payment
        post :worldpay_bg_return

        get :barclaycard
        get :barclaycard_ext
        get :barclaycard_return

        post :credit_payment
        post :pro_forma_payment

        post :notes

        get :complete
      end
    end

    resource :cart, path: '/', only: %i[show destroy update] do
      collection do
        get :merge, action: :choose_merge
        post :merge
        post :quantities
        get :return_cart_items

        post :toggle_gift_wrapping
        post :toggle_prefer_click_and_collect
      end
      member do
        post :add_voucher
      end
      resources :cart_items, only: %i[create update destroy]
    end

  end

  namespace 'front', path: C.account_mount do
    get '/', to: 'accounts#show', as: :customer_root

    devise_for :customer_accounts, path: '',
                                   class_name: 'C::CustomerAccount',
                                   module: 'c/front/devise'

    resources :orders, only: %i[index show], param: :access_token
    resources :addresses, only: %i[index new create destroy]

    resources :wishlist_items, as: :wishlist, path: :wishlist, only: %i[index destroy] do
    end

  end

  # Routes of the main site.
  # Any base route eg http://example.com/<ANYTHING>
  # should route through the contents controller and have
  # a corresponding template.
  #
  # Use any other routes including creating, updating etc through the
  # controller associated with that resource.

  namespace :front_end, path: '/' do
    match '/sitemap', to: 'contents#sitemap',
                      via: 'get', defaults: { format: 'xml' }
    get '/products', to: 'products#index',
                      via: 'get', defaults: { format: 'xml' }


    get '/consent', to: 'customers#get_consent'
    post '/consent', to: 'customers#save_consent'
    get '/unsubscribe', to: 'customers#get_unsubscribe'
    post '/unsubscribe', to: 'customers#save_unsubscribe'

    resources :enquiries, path: 'contact-us', only: :create

    resources :products, only: :show do
      collection { get :search }
    end

    resources :categories, only: :show
    resources :collections, only: :show
    resources :brands, only: %i[index show]
    resources :contents, path: '/', only: :show
    resources :product_reservations, path: 'reserve', only: %i[new create] do
      get :confirmation, on: :member
    end

    get '/shop_by/:id', to: 'shop_by#show', as: :shop_by_show
    get '/shop_by/:id/:nested_id', to: 'shop_by#nested_show', as: :shop_by_nested_show

    post '/deko/csn_return', to: 'deko#csn_return'

    # match ':id__1/:id__2', to: 'contents#show', via: 'get'
    match ':content_type/:id', to: 'contents#show', via: 'get', as: :content_typed
    root 'contents#show'
  end

  mount ActionCable.server => '/cable'
end
