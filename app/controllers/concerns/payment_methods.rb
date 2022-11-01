# frozen_string_literal: true

require_dependency 'worldpay_business_gateway'
require 'payment_sense/request'
require 'payment_sense/response'
require 'worldpay_cardsave/request'
require 'worldpay_cardsave/response'
require 'deko'

module PaymentMethods
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, only: %i[payment_sense_return worldpay_bg_return worldpay_cardsave_return sagepay_3dsf_return sagepay_3dsc_return]
    skip_authorization_check only: :worldpay_bg_return
    skip_before_action :set_cart, only: :worldpay_bg_return
    skip_before_action :cart_exists?, only: :worldpay_bg_return
  end

  # ##############################
  # World Pay JSON API (INACTIVE)
  #
  # Probably doesn't work.
  # Documentation can be found here: https://developer.worldpay.com/jsonapi/docs
  #
  # Uses the inline template form method.
  # ##############################

  def world_pay_payment
    C::Cart.transaction do
      if !params[:order_sale_same_as_shipping].nil? && params[:order_sale_same_as_shipping][:same] == '1'
        @cart.order.update(billing_address: @cart.shipping_address)
      else
        @cart.order.update(billing_params)
      end

      @payment = @cart.order.build_payment(amount_paid: @cart.price)
      @payment.payable = C::PaymentMethod::Worldpay.new(
        ip: request.remote_ip,
        payment_token: params[:payment_token]
      )
      if @payment.save && @cart.order.save
        redirect_to action: :new
      else
        render :get_payment
      end
    end
  end

  # ##############################
  # World Pay Business Gateway
  #
  # Works in a similar manner to Worldpay Cardsave, in that it creates a hidden
  # HTML form that is submitted by the user's browser.
  # ##############################

  def worldpay_bg_payment
    order = @cart.order
    @wp_request = WorldpayBusinessGateway::Request.new(order: order)
    payment = order.build_payment(amount_paid: 0)
    payment.payable = C::PaymentMethod::WorldpayBusinessGateway.new(
      ip: request.remote_ip
    )
    order.save!
    payment.save!
  end

  ##
  # This action is received from Worldpay's servers, not from the user's
  # browse. Hence using +head+, rather than +render+

  def worldpay_bg_return
    return_params = params.permit(
      WorldpayBusinessGateway::Utils::RESPONSE_RETURN_FIELDS
    )
    wp_response = WorldpayBusinessGateway::Response.new(return_params)
    if wp_response.valid? && wp_response.success?
      @cart = C::Order::Sale.from_order_number(wp_response.cart_id)&.cart
      @cart.payment.update(amount_paid: wp_response.amount_paid)
      @cart.payment.payable.update(
        transaction_id: wp_response.trans_id,
        response_body: return_params.as_json
      )
      if @cart.finalize!
        head :ok
      else
        logger.warn("Order #{wp_response.cart_id}: Worldpay BG payment not saved")
        head :internal_server_error
      end
    else
      logger.warn("Order #{wp_response.cart_id}: Worldpay BG Payment not valid or successful")
      head :internal_server_error
    end
  rescue => e
    transaction_id = return_params['transId']
    logger.error("Worldpay BG unknown error (Transaction #{transaction_id})")
    body = [
      "Transaction #{transaction_id}",
      e.to_s,
      e.backtrace.join("\n\n")
    ].join("\n\n")
    ActionMailer::Base.mail(
      from: C.errors_email,
      to: C.errors_email,
      subject: "#{C.store_name} Worldpay BG Failure",
      body: body
    ).deliver
    head :internal_server_error
  end

  # ##############################
  # Sagepay
  #
  # Sagepay uses an embedded form to take card details. The user never leaves
  # the Commercity site and follows the normal checkout process. The embedded
  # form injects a card identifier into the request params that we can use to
  # confirm the transaction.
  #
  # The form requires a session key that is requested from Sagepay using the
  # client's credentials. This key is short-lived (~4 minutes), so the
  # request may be invalid if the user takes too long.
  # ##############################

  ##
  # When the session key expires, the card identifier is not set. Guard against
  # this and, if the identifier is present, process the payment.
  def sagepay_payment
    if params['card-identifier'].nil?
      flash.now[:error] = 'Payment session expired, please try again'
      render :get_payment
    else
      sagepage_process_payment
    end
  end

  ##
  # Set up the Sagepay record with the merchant session key and the card
  # identifier.
  def sagepage_process_payment
    C::Cart.transaction do
      if !params[:order_sale_same_as_shipping].nil? && params[:order_sale_same_as_shipping][:same] == '1'
        @cart.order.update(billing_address: @cart.shipping_address)
      else
        @cart.order.update(billing_params)
      end

      @payment = @cart.order.build_payment(amount_paid: @cart.price)
      @payment.payable = C::PaymentMethod::Sagepay.new(
        ip: request.remote_ip,
        merchant_session_key: params[:merchant_session_key],
        card_identifier: params['card-identifier']
      )
      if @payment.save && @cart.order.save
        redirect_to action: :new
      else
        render :get_payment
      end
    end
  end

  def sagepay_session_key
    respond_to do |format|
      format.json do
        render json: C::SAGEPAY_API.session_key
      end
    end
  end

  # {"acsUrl"=>"https://test.sagepay.com/mpitools/accesscontroler?action=pareq"
  # "paReq"=>"eJxVUttugkAQfe9XED6AYQHxknENrbYljYZW0zR9I8tESeXiAkX/vrsIteVl58xMzp5zFlycs6PxTbJKi3xuMss2F/wOdwdJtNySaCRxXFNVxXsy0mRuOjbznSlz7PGEMc9lzPZNjlHwRieOPQ9XNBZDGKAikOIQ5zXHWJzuww33PN/1Rwg9xIxkuOQOs6/f9US4tjGPM+JbpSCKL0vKikCIoslrhG6AHZAXPnF8hAFgI4/8UNflDKBtW0sbKOOLJQqr+ULQU4SbrqjRVaXYzmnCK9gnIeyC9/px8xRm3sfny+o1adORu5oj6A1M4pq4YyvJE+YbzJu57sxWnrs+xpmWwafaRF9jqa8I/gz+NlAlLSkXg4sBIZ3LIie14SD81phQJbpEDBWJsY5CdbFuIdyMPDzruEWtEmQ66a7SfKmKR+ked4QaIOhd6B8R+udW1b/f4AdhwLS2"
  # "transactionId"=>"8BE39265-4BE9-11C0-68BE-B0C8672B704D"
  # "controller"=>"c/front/checkouts"
  # "action"=>"sagepay_3dsf_redirect"}
  def sagepay_3dsf_redirect
    @acsUrl = params['acsUrl']
    @paReq = params['paReq']
    @transactionId = params['transactionId']
    @md = @cart&.order&.id
  end

  # "PaRes"=>"eJydVtuSokgQfZ+v6HAi9sXo5iIi9tJuFBcRWkQQ8fKGUBSgAnIR8OsXxb5Mz+zG7hBhQCaZJ89JKsti/6qOh4czTLMgjl46xBPeeYCRE7tBhF46S3P8yHT+Gn1jTT+FUFhAp0jhiFVhltkIPgTuS4fECZocEiRJ03ivTxIEhXdG7BwYMLu9T+wUZs/4E00xQ4ZgegxODwZEn26C7mVHTdUngsXezAY+dXw7ykes7Zw4eTaiKLpH91nsbrJHmMrCiCTw9mrvLNa6Wewjf15cn7KGchW4o51pO+K6ErVqWHaNWueK0JtiOsar4guLXSNY187hiMQbaIagH4j+M049kw30zc8mVzhwjIsGe3it+NnBNr1Jm97VI4akWezdYmGVxBFsIkgWe39msQ9uiR2NqCE5vMvBm+yrizXXIzYPjj8R6jXNuvnZLLfzIhttWOz+xDr2+TwCAHDAMPr7Eny9GqG3EBY6wQhvenq937LAAcVpkPvHK88fHSx2pYLdPmrTo+x5EaCoqZfCh2b5RNmzm710/DxPnjGsLMunsvcUpwgjGy0YPsSaGDcL0PdOs5DuydCVIy9ubd6O4ihw7ENwsfNmAagw92P34b38r6BN44pOYIbIPzbwjw5BRY9XD94j+h3so9CN5X9B/Eo2zezHzLeJNzADevD6QeHD0pBfOnctZmpHmRenx+yL/f+KwegMD3EC3cfsjfNb3f+I+K8N+b5q0vj4eGxWXnYDxn7BXQgQzPLf6dXnPrUoln0o4KhAWjXdxKvZipouemSfXKLar4xXTaRebhQ+B7ek3tt8t78ulvdvek/SmX12JnznrClWIeeRbq7QKd67F00hbGIhnUy+2NmvJZksAzBBO6YKd+5Rt6X0VZAcUVkn23Tan04vyJD++F65f347loNUm0S7gvYGwTHYRK5qM0SxJhWc6GlBXaB6YJTGctcLaahOLIJSPBGq5SHhD1mfu9ABULBTFxcsG7SICb1m0GYiavPCu/jceJzuXz7UfVZzVfgK66vc35msdR8fCnZuf1g8TPPAa4ar2b6+qbLMz0yeB1sagVLmAJBFHSy32xDMOLQ/+ftAGpY4B/TlGAicp+pZyesbwdJ1SSwVa3ER5yrAJUAsxVYZz6mSKQ2LbfP7FD1poseWKWoqKG/RvK+OlxPl7E5QJYZA59DM4kBm8hZX73oGJYuE3iIuPmWB6j2rnPjOTBX0UjVFXDVBPQt1cnX1XcRyFjaRb77wg3eL+Cv2v8u7RfwV+3/ijbZMKegb5TXeyv7ZmQFd5DgdCGiDA1WWlBYRxBIHXhtyTkTOJXy7902R4knapA/OAjfdKaWN50snpEXb7gszFS0nxHbthOu4W2+mVl/BgpNl7R2ULe4c0zijA4JIZ5HU8/zuPNJWcZUdkY76tulQmEmH3XQLeSfabSd78Hoea2Crk4ce0S2sVYyqaX+e27KzJs9+i4h6c96y5RiEQk+ju1U3YKxFJR8AUpuVJH5VOW5ViiCMejm/0HoFOQ/n5SJFyX7RItaaI0jlyQ3qMrBmSdc47+u8AL10eaKsaAutgKD0Aq+wCyZ2l7445EI6NJfQ8Mn9cHhmao87Ofyq2ByY7b2PY0k0TW8N4NY+ZxpSMi1Lw+ow63Y9uaajgXZBIglmeerTC2m3EqooUAzhnIzHzeo3A3qfyhfaU8+0eJ/Qn4bo3fsxaM3EfppfYwF+dKixWxya/+ZY0Le1t2F2xnExVk003SXzk1VNjRl+RtRyaNTz2EjSvYrXnO5ZB7eewXCgoHy9j7qvibUyar5S+CK4nKat3PUqI52d251QXadvh1Jtc7xwSGaXcDg/zen8QCm1m++hDk7MkuIOgr321nTfsgNBPO+7ROxXnt2VBIdRrBYxDhCvzp1BOpjQ08qaisGy3anfRNwUiW+nGKAD7vb63XPfxX/oAfZjj7CPTW70ZRu8Hd5uZ8vrmePzmfNvLBRz6w==", 
  # "MD"=>"1690",
  def sagepay_3dsf_return
    begin
      paRes = params['PaRes']
      orderId = params['MD']

      payable = C::Order::Sale.find(orderId).payment.payable

      transactionId = payable.transaction_id
      response = C::SAGEPAY_API.send_fallback_pares(paRes, transactionId)
      status = response['status']
    
      if status != "Authenticated"
        raise "Failed to auth the 3dsv1 with opayo"
      end 

      transaction = C::SAGEPAY_API.get_transaction(transactionId)

      if transaction['status'] != 'Ok'
        raise transaction['statusDetail']
      end

      payable.update(threed_secure_status: 'ok')

      return repost(checkout_path, options: {authenticity_token: :auto})
    rescue => e
      puts e
      flash[:error] = e
      redirect_to action: :get_payment
    end
  end

  # {"acsUrl"=>"https://test.sagepay.com/mpitools/accesscontroler?action=pareq"
  # "cReq"=>"eJxVUttugkAQfe9XED6AYQHxknENrbYljYZW0zR9I8tESeXiAkX/vrsIteVl58xMzp5zFlycs6PxTbJKi3xuMss2F/wOdwdJtNySaCRxXFNVxXsy0mRuOjbznSlz7PGEMc9lzPZNjlHwRieOPQ9XNBZDGKAikOIQ5zXHWJzuww33PN/1Rwg9xIxkuOQOs6/f9US4tjGPM+JbpSCKL0vKikCIoslrhG6AHZAXPnF8hAFgI4/8UNflDKBtW0sbKOOLJQqr+ULQU4SbrqjRVaXYzmnCK9gnIeyC9/px8xRm3sfny+o1adORu5oj6A1M4pq4YyvJE+YbzJu57sxWnrs+xpmWwafaRF9jqa8I/gz+NlAlLSkXg4sBIZ3LIie14SD81phQJbpEDBWJsY5CdbFuIdyMPDzruEWtEmQ66a7SfKmKR+ked4QaIOhd6B8R+udW1b/f4AdhwLS2"
  # "transactionId"=>"8BE39265-4BE9-11C0-68BE-B0C8672B704D"
  # "controller"=>"c/front/checkouts"
  # "action"=>"sagepay_3dsf_redirect"}
  def sagepay_3dsc_redirect
    @acsUrl = params['acsUrl']
    @cReq = params['cReq']
    @transactionId = params['transactionId']
    @md = @cart&.order&.id
  end


  def sagepay_3dsc_return
    begin
      cRes = params['cres']
      threeDSSessionData = params['threeDSSessionData']
      orderId = Base64.decode64(threeDSSessionData)

      payable = C::Order::Sale.find(orderId).payment.payable

      transactionId = payable.transaction_id

      response = C::SAGEPAY_API.send_challenge_cres(cRes, transactionId)
      status = response['status']
    
      if status != "Ok"
        throw response['statusDetail']
      end 

      payable.update(threed_secure_status: 'ok')

      return repost(checkout_path, options: {authenticity_token: :auto})
    rescue => e
      puts e
      flash[:error] = e
      redirect_to action: :get_payment
    end
  end

    

  # ##############################
  # V12
  #
  # The V12 magic mostly happens in the classes in `lib/v12/v12_api_classes/`.
  # The checkout process is confirmed on the V12 site itself. The user is
  # redirected to the V12 site and is not returned to the checkout process.
  #
  # V12 does not notify us of the status of the application, so we have to
  # check periodically (see C::V12PaymentsJob).
  # ##############################

  def v12_payment
    unless C.v12_finance
      flash.now[:error] = 'V12 Finance not enabled'
      render :get_payment
      return
    end

    # V12's Interest-Free Finance package
    deposit = (@cart.price / 10.0).to_f
    v12_payment_option = C::PaymentMethod::V12Finance.find_finance_option(params[:v12_payment_option].to_i)
    raise C::PaymentMethod::V12Finance::UnknownFinanceOption if v12_payment_option.nil?
    finance = V12Order.new(v12_payment_option.id, v12_payment_option.guid,
                           "#{@cart.order.order_number}_#{Time.zone.now.utc.iso8601}", deposit)

    cart.cart_items.each do |item|
      finance.add_line(item.quantity, item.variant.sku, item.variant.name,
                       item.price.to_f)
    end

    # Delivery is considered another line on the invoice.
    finance.add_line(1, '', @cart.delivery.name, @cart.delivery.price.to_f)

    application = V12Application.new(
      order: finance,
      retailer: V12Retailer.new(
        ENV['V12_ID'],
        ENV['V12_GUID'],
        ENV['V12_AUTH_TOKEN']
      )
    )
    begin
      if application.send && application.status == :acknowledged
        @payment = @cart.order.build_payment(amount_paid: @cart.price)
        @payment.payable = C::PaymentMethod::V12Finance.new(
          ip: request.remote_ip,
          application_id: application.id,
          application_guid: application.guid,
          last_status: application.status
        )
        if @payment.save && @cart.order.save
          redirect_to application.url
        else
          flash.now[:error] = 'There was a problem'
          logger.error 'There was a problem with V12 Finance'
          render :get_payment
        end
      else
        flash.now[:error] = "Finance declined (status: #{application.status})"
        logger.info "Finance declined (status: #{application.status})"
        render :get_payment
      end
    rescue SocketError
      flash.now[:error] = 'Unable to connect to V12 Finance. Please try again later.'
      logger.warn 'Unable to connect to V12 Finance. Please try again later.'
      render :get_payment
      # rescue JSON::ParserError
      #   flash.now[:error] = "An error occurred processing your request with V12 Finance."
      #   logger.debug "An error occurred processing your request with V12 Finance."
      #   render :get_payment
    end
  end

  # ##############################
  # Paypal Express
  # ##############################

  def express_payment
    iso2 = @cart.shipping_address.country.iso2

    # Because some people want to have England/Wales/NI/Scotland as separate countries, they are stored with fake iso2's of GB_
    # Paypal only supports real ones so they discard the shipping address if it's not valid
    # so here, we check if it has the hack prefix and then send up GB which will we will check on the other side
    if iso2.include?("GB_")
      iso2 = "GB"
    end

    response = C::EXPRESS_GATEWAY.setup_purchase(
      @cart.price.fractional,
      ip: request.remote_ip,
      return_url: express_payment_return_checkout_url,
      cancel_return_url: express_payment_cancel_checkout_url,
      currency: 'GBP',
      allow_guest_checkout: true,
      no_shipping: true,
      address_override: true,
      address_override: 1,
      address: {
        name: @cart.shipping_address.name, 
        address1: @cart.shipping_address.address_one, 
        address2: @cart.shipping_address.address_two, 
        city: @cart.shipping_address.city,
        state: @cart.shipping_address.region,
        zip: @cart.shipping_address.postcode,
        country: iso2,
        phone: @cart.shipping_address.phone, 
      },
    )

    @payment = @cart.order.build_payment(amount_paid: 0)

    @payment.payable = C::PaymentMethod::PaypalExpress.new(
      ip: request.remote_ip
    )
    if @payment.save && @cart.order.save
      redirect_to C::EXPRESS_GATEWAY.redirect_url_for(response.token)
    else
      render :get_payment
    end
  rescue ActiveMerchant::ConnectionError
    flash[:danger] = 'Cannot reach the Paypal servers!'
    logger.warn 'Active Mechant Connection Error'
    redirect_to action: :get_payment
  end

  def express_payment_return
    if @cart.payment.payable.update(payment_token: params[:token],
                                    payer_id: params['PayerID'])
      @cart.payment.update(amount_paid: @cart.price)
      redirect_to action: :new
    else
      render :get_payment
    end
  end

  def express_payment_cancel
    @cart.payment.destroy!
    redirect_to action: :new
  end

  # ##############################
  # PaymentSense
  #
  # Works almost identically to Worldpay Cardsave; see the documentation for
  # that.
  # ##############################

  def payment_sense_payment
    order = @cart.order
    @ps_request = PaymentSense::Request.new(
      order: order,
      callback_url: payment_sense_return_checkout_url(secure: true)
    )
    payment = order.build_payment(amount_paid: 0)
    payment.payable = C::PaymentMethod::PaymentSense.new(
      ip: request.remote_ip,
      request_string: @ps_request.to_query_string(
        PaymentSense::Utils::REQUEST_FORM_FIELDS
      )
    )
    order.save!
    payment.save!
  end

  def payment_sense_return
    return_params = params.permit(
      PaymentSense::Utils::RESPONSE_HASH_FIELDS + ['HashDigest']
    )
    ps_response = PaymentSense::Response.new(return_params)

    if ps_response.valid? && ps_response.success?
      @cart.payment.update(amount_paid: ps_response.amount_paid)
      @cart.payment.payable.update(
        transaction_id: "#{ps_response.cross_reference} #{ps_response.order_id}",
        cross_reference: ps_response.cross_reference,
        response_string: ps_response.to_query_string(
          PaymentSense::Utils::RESPONSE_STORE_FIELDS
        )
      )

      create
    else
      flash[:error] = 'Unable to process your payment.'
      render :get_payment
    end
  end

  # ##############################
  # Worldpay Cardsave
  # ##############################

  ##
  # Builds a Cardsave request using the order, setting the return URL as
  # #worldpay_cardsave_return. Also sets up the payment record for the order.
  # The view for this action renders the form as hidden and provides a button
  # to submit the form to Cardsave.

  def worldpay_cardsave_payment
    order = @cart.order
    @ps_request = WorldpayCardsave::Request.new(
      order: order,
      callback_url: worldpay_cardsave_return_checkout_url(secure: true)
    )
    payment = order.build_payment(amount_paid: 0)
    payment.payable = C::PaymentMethod::WorldpayCardsave.new(
      ip: request.remote_ip,
      request_string: @ps_request.to_query_string(
        WorldpayCardsave::Utils::REQUEST_FORM_FIELDS
      )
    )
    order.save!
    payment.save!
  end

  ##
  # Builds a Cardsave request using the order, setting the return URL as
  # #worldpay_cardsave_return. Also sets up the payment record for the order.
  # The view for this action renders the form as hidden and provides a button
  # to submit the form to Cardsave.

  def worldpay_cardsave_return
    return_params = params.permit(
      WorldpayCardsave::Utils::RESPONSE_HASH_FIELDS + ['HashDigest']
    )
    ps_response = WorldpayCardsave::Response.new(return_params)
    if ps_response.valid? && ps_response.success?
      @cart.payment.update(amount_paid: ps_response.amount_paid)
      @cart.payment.payable.update(
        cross_reference: ps_response.cross_reference,
        response_string: ps_response.to_query_string(
          WorldpayCardsave::Utils::RESPONSE_STORE_FIELDS
        )
      )
      redirect_to action: :create
    else
      flash[:error] = 'Unable to process your payment.'
      render :get_payment
    end
  end

  # ##############################
  # Credit
  #
  # Credit payments are used to allow trade customers to 'put things on the
  # slate.' To be used, the global use_credit setting has to be enabled and the
  # user has to have a payment type of :credit.
  #
  # The user will follow a normal checkout flow without entering payment
  # details. The order will be placed as awaiting dispatch, but will show
  # amount paid as zero.
  # ##############################

  def credit_payment
    if C.use_credit && current_front_customer_account.credit?
      order = @cart.order
      payment = order.build_payment(amount_paid: 0)
      payment.payable = C::PaymentMethod::Credit.new(ip: request.remote_ip)
      if payment.save && order.save && @cart.save
        redirect_to action: :new
        return
      end
    else
      flash[:error] = 'Unable to give credit'
      render :get_payment
    end
  end

  def pro_forma_payment
    if current_front_customer_account&.customer&.is_trade?
      
      order = @cart.order
      payment = order.build_payment(amount_paid: @cart.price)

      payment.payable = C::PaymentMethod::ProForma.new(ip: request.remote_ip)

      if payment.save && order.save && @cart.save
        redirect_to action: :new
        return
      end

    else
      flash[:error] = 'Unable to pay by pro forma'
      render :get_payment
    end
  end

  # ##############################
  # Deko
  #
  # Official Documentation: https://docs.dekopay.com/
  #
  # All classes are located in 'lib/deko', but grouped into files of a similar
  # type.
  #
  # To send a request to Deko, argument classes must be used to specify the
  # Consumer, the Finance requested, the Goods ordered and Identification of
  # the order.
  #
  # The user is not returned to the checkout. We find out the status of the
  # loan application via Credit Status Notification. Several of these are sent
  # out during the course of an application, and C::FrontEnd::DekoController
  # handles them.
  # ##############################

  def deko_payment
    unless C.deko_finance
      flash.now[:error] = 'Deko Finance not enabled'
      render :get_payment
      return
    end

    code = params[:deko_payment_option]
    slider_value = params[:deko_deposit_slider].to_i
    raise 'Deko Option not in configuration!' unless C::DEKO_CONFIG.pluck(:key).include?(code)

    order_number = @cart.order.order_number

    # Normalise deposit
    min_pc = C.deko_finance_min_deposit_pc
    max_pc = C.deko_finance_max_deposit_pc
    cart_price_pennies = @cart.price.fractional
    factor = ((slider_value * 2).round(-1) / 2).clamp(min_pc, max_pc) / 100.0
    deposit = cart_price_pennies * factor

    customer = @cart.order.customer
    first_name, _, last_name = customer.name.rpartition(' ')
    consumer = Deko::Consumer.new(
      forename: first_name,
      surname: last_name,
      email_address: customer.email,
      mobile_number: customer.mobile&.tr(' ', '')
    )
    finance = Deko::Finance.new(code: code, deposit: deposit)
    goods = Deko::Goods.new(
      description: "#{C.store_name} Order ##{order_number}",
      price: cart_price_pennies.to_s
    )
    identification = Deko::Identification.new(
      retailer_unique_ref: "O##{order_number}:#{SecureRandom.hex(8)}"
    )
    deko_request = Deko::Request.new(
      finance: finance,
      goods: goods,
      consumer: consumer,
      identification: identification
    )

    deko_response = deko_request.make_request
    if deko_response.success?
      @payment = @cart.order.build_payment(amount_paid: @cart.price)
      @payment.payable = C::PaymentMethod::DekoFinance.new(
        ip: request.remote_ip,
        unique_reference: identification.retailer_unique_ref
      )
      if @payment.save && @cart.order.save
        redirect_to deko_response.redirection_url
      else
        flash.now[:error] = 'There was a problem'
        logger.error 'There was a problem with Deko Finance'
        render :get_payment
      end
    else
      flash.now[:error] = 'Finance declined. Please try again later.'
      logger.info "Finance declined (status: #{deko_response.error_message})"
      render :get_payment
    end
  end

  def barclaycard_ext
    head 404 unless (@cart = C::Barclaycard.cart_from_param(params[:orderID]))
    page = Nokogiri::HTML(render_to_string(template: 'c/front/checkouts/barclaycard_ext'))
    page.xpath('//*[@src or @href]').each do |node|
      node['src'] = C.absolute_url(node['src']) if node['src']
      node['href'] = C.absolute_url(node['href']) if node['href']
    end
    render html: ActiveSupport::SafeBuffer.new(page.to_s)
  end

  def barclaycard_return
    if C::Barclaycard.valid_signature?(request.query_parameters)
      @cart = C::Barclaycard.cart_from_param(params[:orderID])

      if @cart && params[:STATUS].to_s.in?(%w[5 9 51 91])
        @cart.order.build_payment(amount_paid: params[:amount])
        @cart.order.payment.build_payable
        @cart.save!
        @cart.finalize!
        @cart.destroy!
        redirect_to front_order_path(@cart.order.access_token)
        return
      end
    end

    flash[:error] =
      'There was a problem processing your Barclaycard payment. Please try again later.'
    redirect_to action: :get_payment
  end
end
