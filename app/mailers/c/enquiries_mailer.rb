# frozen_string_literal: true

module C
  class EnquiriesMailer < ApplicationMailer
    def new_enquiry(enq)
      @enquiry = enq
      @title = 'A new enquiry has been made'
      @email = recipient_addresses
      @unsub_email = @enquiry.email
      mail subject: 'New Enquiry', to: @email
    end

    def customer_reservation_email(reservation)
      @reservation = reservation
      @product = @reservation.product_variant
      @email = reservation.email
      @unsub_email = @email
      mail subject: 'Thank you for your reservation', to: @email
    end
  
    def store_reservation_email(reservation)
      @reservation = reservation
      @product = @reservation.product_variant
      @email = recipient_addresses
      mail subject: 'New Reservation', to: @email
    end

    def new_consent(email, data)
      @email = email
      @data = data
      mail subject: 'Data Consent Submission', to: C.email.present? ? C.email : recipient_addresses
    end

    def out_of_stock_report
      active_out_of_stock_products = C::Product::Variant.published.for_display.where('current_stock < 1').where(main_variant: true)
      out_stock_lines = active_out_of_stock_products.pluck(:sku, :oe_number, :name)
      headers = ["SKU", "OE", "NAME"]
      
      full_csv = CSV.generate(headers: true) do |csv|
        csv << headers
        out_stock_lines.each do |line|
          csv << line
        end
      end

      to = C.out_of_stock_report_email ? C.out_of_stock_report_email : recipient_addresses

      attachments["#{C.store_name}_Out_Of_Stock_Report_#{Time.now.strftime("%d%m%Y")}.csv"] = { mime_type: 'text/csv', content: full_csv }
      mail subject: "#{C.store_name} Out Of Stock Report #{Time.now.strftime("%d%m%Y")}", to: to
    end

    private

    def recipient_addresses
      C::NotificationEmail.enquiry_recipients
    end
  end
end
