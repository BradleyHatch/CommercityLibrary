# frozen_string_literal: true

require_dependency 'c/front_controller'

module C
  module Front
    class CheckoutsController < C::FrontController
      include C::CartsHelper
      layout :checkout_or_cart_layout

      skip_before_action :authenticate_front_customer_account!, except: %i[choose_merge merge]

      before_action :set_cart, except: %i[complete barclaycard_ext barclaycard_return]
      before_action :set_weight, only: %i[get_delivery delivery]
      before_action :set_zone, only: %i[get_delivery delivery]
      before_action :cart_exists?, except: %i[complete barclaycard_ext barclaycard_return sagepay_3dsf_return]
      before_action :check_flag_stock, only: %i[get_address get_delivery get_payment]
      before_action :redirect_if_no_stock, only: %i[get_account get_address new_address get_delivery get_payment]

      # To skip actions defined above, the payment methods concern needs to be
      # included below them.
      include C::PaymentMethods

      def new
        @cart.update(accepted_privacy_policy: true)
        current_front_customer_account.update(accepted_privacy_policy: true) if current_front_customer_account.present?

        # this is the bit where an order is made
        @cart.begin_checkout
        @cart.check_country
        @cart.integrity_check

        # lets just add the notes in here
        notes_body = @cart.cart_items.where.not(variant_id: nil).map do |cart_item|
          cart_item_joint_note = cart_item.cart_item_notes.map do |note|
            "#{note.name}: #{note.value}"
          end.join(", ")
          next if cart_item_joint_note.blank?
          "Product #{cart_item.variant.sku} - #{cart_item_joint_note}"
        end.compact.join(", ")

        if notes_body.present?
          cart.order.update(checkout_notes: notes_body)
        end

        if %i[account address delivery payment].include?(@cart.stage)
          redirect_to action: @cart.stage
        elsif @cart.order&.payment&.payable&.off_site_confirmation? &&
              @cart.order&.payment&.paid? && @cart_error.nil?
          create
        else
          redirect_if_no_stock
        end
      end

      def get_account
        # Customer is set for the cart at log in. Customer is set for the order
        # in begin_checkout. Just redirect.
        return unless front_customer_account_signed_in? && @cart.order.customer.present?
        redirect_to checkout_path
      end

      def account
        if @cart.update(account_params)
          redirect_to action: :new
        else
          render :get_account
        end
      end

      def get_address
        @addresses = @cart&.customer&.addresses || []

        if C.validates_shipping_address_phone_number
          @addresses = @addresses.select { |address| address.phone.present? }
        end

        redirect_to action: :new_address if @addresses.empty? || C.gift_wrapping
      end

      def new_address
        @address = @cart.build_shipping_address?
      end

      def create_address
        if !@cart 
          redirect_to main_app.root_path, notice: 'Apologies, Your cart has expired'
          return
        end

        email = front_customer_account_signed_in? ? current_front_customer_account.email : params[:cart][:email]

        @cart.assign_attributes(
          email: email, 
          prefer_click_and_collect: params[:cart][:prefer_click_and_collect].present? ? params[:cart][:prefer_click_and_collect] : false
        )

        address_params_hash = address_params.to_h
        
        if @cart.prefer_click_and_collect
          address_params_hash[:order_attributes][:shipping_address_attributes]["address_one"] = C.click_and_collect_address_one
          address_params_hash[:order_attributes][:shipping_address_attributes]["address_two"] = ""
          address_params_hash[:order_attributes][:shipping_address_attributes]["address_three"] = ""
          address_params_hash[:order_attributes][:shipping_address_attributes]["city"] = C.click_and_collect_city
          address_params_hash[:order_attributes][:shipping_address_attributes]["region"] = C.click_and_collect_county
          address_params_hash[:order_attributes][:shipping_address_attributes]["postcode"] = C.click_and_collect_postcode
          address_params_hash[:order_attributes][:shipping_address_attributes]["country_id"] = C::Country.find_by_iso2('GB')&.id
        end

        shipping_address_attributes = address_params_hash[:order_attributes][:shipping_address_attributes]

        info = address_params_hash[:order_attributes][:info]
        info_attributes = { info: info }

        if @cart&.order&.shipping_address
          if info.present?
            @cart.order.assign_attributes(info_attributes)
          end
          @cart.order.shipping_address.assign_attributes(shipping_address_attributes)
        else
          @cart.assign_attributes(address_params_hash)
        end

        # If it's a guest checkout, build a customer if needed and then assign relevant attrs
        if !front_customer_account_signed_in?
          @cart.build_customer?

          @cart.order.customer&.assign_attributes(
            name: shipping_address_attributes[:name],
            phone: shipping_address_attributes[:phone],
            mobile: shipping_address_attributes[:mobile],
            email: email
          )
        end

        valid = true

        if C.validates_shipping_address_phone_number
          valid = @cart.valid? && @cart.order.shipping_address.phone.present?

          if @cart.order.shipping_address.phone.blank?
            @cart.errors.add(:'order.shipping_address.phone', "can't be blank")
          end
        end

        if valid && @cart.save
          # Update any blank customer attributes from the shipping address
          %i[name phone mobile].each do |attr|
            next if @cart.order.customer[attr].present?
            @cart.order.customer.update(shipping_address_attributes.slice(attr))
          end

          @cart.order.shipping_address.update(customer: @cart.order.customer)
          @cart.copy_contact_details_to_order
          @cart.order.update(delivery: nil)
          redirect_to action: :new
        else
          render :new_address
        end
      end

      def address
        if @cart.update(address_params)
          @cart.generate_customer_from_address_details
          @cart.copy_contact_details_to_order
          @cart.order.update(delivery: nil)
          redirect_to action: :new
        else
          render :get_address
        end
      end

      def get_billing_address; end

      def billing_address; end

      def set_delivery_services
        @delivery_click_and_collect_mix = false
        
        if @cart.has_delivery_override?
          @delivery_override = true
          @delivery_services = []  

          @delivery_click_and_collect_mix = false
          @delivery_click_and_collect_valid = false
        else
          @delivery_override = false
          @delivery_services = C::Delivery::Service.ordered.for_cart_price(@cart.price.fractional)

          @delivery_click_and_collect_mix = false
          @delivery_click_and_collect_valid = false

          if C.click_and_collect
            if cart.prefer_click_and_collect
              @delivery_click_and_collect_valid = true
              @delivery_services = @delivery_services.select { |service| service.click_and_collect? }
            else
              @delivery_click_and_collect_valid = false
            end
          else
            # this probably shouldn't be here but there really isn't a better place i can see to put some bespoke logic
            if @delivery_services.find { |service| service.click_and_collect? }.present?
              cart_variant_items = @cart.cart_items.where.not(variant_id: nil)

              @delivery_click_and_collect_valid = cart_variant_items.all? { |cart_variant_item| cart_variant_item.variant.master.main_variant.click_and_collect? }

              # mixed if the above is false but we still find at least one product which is flagged as click and collect
              # we will use this to print a separate message
              @delivery_click_and_collect_mix = !@delivery_click_and_collect_valid && cart_variant_items.find { |cart_variant_item| cart_variant_item.variant.master.main_variant.click_and_collect? }.present?
            end
          end

          if !@delivery_click_and_collect_valid
            @delivery_services = @delivery_services.select { |service| !service.click_and_collect? }
          end
        end
      end

      def get_delivery
        delivery_service_id = @cart.order&.delivery&.delivery_service_id

        @delivery = @cart.order.build_delivery

        if delivery_service_id.present?
          @delivery.delivery_service_id = delivery_service_id
        end

        set_delivery_services
      end

      def delivery
        if delivery_params[:delivery_service_id] == 'override'
          @delivery = @cart.build_overridden_delivery
        else
          @delivery = @cart.build_selected_delivery(delivery_params)
        end
        
        if !@cart.tax_liable?
          @delivery.tax_rate = 0
        end

        if @cart.valid_for_price?
          if @delivery.save && @cart.order.save
            @cart.payment.destroy! if @cart.payment?
            redirect_to action: :new
            return
          end
        else
          flash.now[:danger] = 'Delivery not valid for price'
        end

        set_delivery_services
        render :get_delivery
      end

      def get_payment
        @cart.destroy_payment!
        @cart.order.update(status: :awaiting_payment)
        @cart.build_payment_fields
      end

      ###
      # This is the create action of the checkout - finishing off the payment
      ###
      def create
        @cart.cart_items.each do |item|
          if item.order_item.present?
            item.order_item.update(gift_wrapping: item.gift_wrapping)
          end
        end
        
        # byebug
        user_params = {
          "browserUserAgent" => request.user_agent,
          "browserIP" => request.remote_ip,
          "browserAcceptHeader" => request.headers['Accept'],
          "browserJavaEnabled" => params['browserJavaEnabled'],
          "browserLanguage" => params['browserLanguage'],
          "browserColorDepth" => params['browserColorDepth'],
          "browserScreenHeight" => params['browserScreenHeight'],
          "browserScreenWidth" => params['browserScreenWidth'],
          "browserTZ" => params['browserTZ'],
        }

        cart_finalize = @cart.finalize!(user_params)

        if cart_finalize.is_a?(Hash)
          if cart_finalize['type'] == "SagePay3dF" && cart_finalize['acsUrl'].present? && cart_finalize['paReq'].present?
            return redirect_to sagepay_3dsf_redirect_checkout_path(
              acsUrl: cart_finalize['acsUrl'],
              paReq: cart_finalize['paReq'],
              transactionId: cart_finalize['transactionId'],
            )
          end
          if cart_finalize['type'] == "SagePay3dC" && cart_finalize['acsUrl'].present? && cart_finalize['cReq'].present?
            return redirect_to sagepay_3dsc_redirect_checkout_path(
              acsUrl: cart_finalize['acsUrl'],
              cReq: cart_finalize['cReq'],
              transactionId: cart_finalize['transactionId'],
            )
          end
        elsif cart_finalize
          @cart.destroy! # Shouldn't need to, but will anyway
          redirect_to front_order_path(@cart.order.access_token)
          return
        end

        @cart_error = true
        flash.now[:error] = 'There was a problem authorizing your payment'

        if @cart.country_didnt_match_from_paypal
          @cart.destroy_payment!
          @cart.destroy_address!
          @cart.destroy_delivery!
          flash[:error] = 'There was a problem authorizing your payment'
          redirect_to action: :new
          return  
        end

        redirect_to action: :new

      rescue SagepayAPITransactionRejected
        @cart_error = true
        flash[:error] = 'There was a problem with your payment details, please try again'
        redirect_to action: :get_payment
      end

      def cancel
        @cart.payment.cancel!
        @cart.order.update(status: :cancelled)
        @cart.destroy
        redirect_to '/', notice: 'Checkout Cancelled'
      end

      def notes
        redirect_to new_checkout_path and return if params[:order_sale][:checkout_notes].blank?

        if @cart.order.update(order_notes_params)
          redirect_to new_checkout_path(notes_saved: true)
        else
          redirect_to new_checkout_path
        end
      end

      private

      def set_cart
        @cart = cart
      end

      # Used in the get_delivery view for presenting delivery services
      def set_weight
        @weight = @cart.total_weight
      end

      # Used in the get_delivery view for presenting delivery services
      def set_zone
        @zone = @cart.shipping_address.country.zone
      rescue => e
        require 'json'
        cart_body = JSON.pretty_generate(
          @cart.as_json(include: %i[shipping_address order customer])
        )
        ActionMailer::Base.mail(
          from: C.errors_email,
          to: C.errors_email,
          subject: "#{C.store_name} Cart set zone error",
          body: "Made on cart:\n\n#{cart_body}" + e.to_s + "\n\n" + e.backtrace.join("\n\n")
        ).deliver
        flash[:error] = 'There was a problem with your address. Please try again or contact us if this happens again.'
        redirect_to cart_path
      end

      def cart_exists?
        redirect_to c.front_customer_root_path, notice: 'Sorry, we lost your cart.' unless @cart.persisted?
      end

      def account_params
        params.permit(:anonymous)
      end

      def general_address_fields
        %i[name address_one address_two address_three city region
           postcode country_id phone mobile]
      end

      def address_params
        params.require(:cart).permit(
          order_attributes: [
            :id, :shipping_address_id, :customer_id, :prefer_click_and_collect, {
              info: C.order_info_fields.keys,
              shipping_address_attributes: general_address_fields
            }
          ]
        )
      end

      def billing_params
        params.require(:order_sale).permit(
          billing_address_attributes: general_address_fields
        )
      end

      def delivery_params
        params.require(:order_delivery).permit(:delivery_service_id, :terms_carriage_charges, :terms_additional_charges)
      end

      def order_notes_params
        params.require(:order_sale).permit(:checkout_notes)
      end

      def check_flag_stock
        @flag_stock = false
        @cart.cart_items.each do |item|
          next if item.voucher
          @flag_stock = true if item.quantity > item.variant.current_stock
        end
      end

      def redirect_if_no_stock
        if C.no_checkout_when_no_stock && @cart.cart_items.any? { |c| !c.voucher && c.quantity > c.variant.current_stock }
          flash[:error] = 'Your cart contains products with more quantity selected than we have in stock.'
          redirect_to cart_path
        end
      end

      def checkout_or_cart_layout
        'c/checkout_application' unless action_name == 'get_account' || action_name == 'complete'
      end
    end
  end
end
