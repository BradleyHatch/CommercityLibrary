# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module FrontEnd
    class ContentsController < MainApplicationController
      before_action :set_content, only: :show

      def show
        assign_page_info @content.page_info
        render @content.template
      rescue ActionView::MissingTemplate
        raise ActiveRecord::RecordNotFound
      end

      def sitemap
        @content =  C::Content.all
        @products = C::Product::Variant.all.active
        respond_to do |format|
          format.xml
        end
      end

      private

      def set_content
        @content = C::Content.from_url(params[:id])
        return if params[:content_type].present? || @content.basic_page?
        redirect_to("/#{@content.content_type}/#{params[:id]}", status: 301)
      end
    end
  end
end
