# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class EnquiriesController < MainApplicationController
      def create
        @content = C::Content.from_url('contact-us')
        assign_page_info @content.page_info
        @enquiry = C::Enquiry.new(enquiry_params)
        if recaptcha && @enquiry.save
          C::EnquiriesMailer.new_enquiry(@enquiry).deliver_now
          redirect_to '/thanks'
        elsif params[:redirect_content]
          @content = C::Content.find(params[:redirect_content])
          render "c/front_end/contents/#{@content.template}"
        elsif params[:redirect_product]
          @product = C::Product::Variant.find(params[:redirect_product])
          render 'c/front_end/products/show'
        else
          render 'c/front_end/contents/contact_us'
        end
      end

      private

      def recaptcha
        return true unless C.recaptcha
        verify_recaptcha(model: @enquiry)
      end

      def enquiry_params
        params.require(:enquiry).permit(:name, :email, :body)
      end
    end
  end
end
