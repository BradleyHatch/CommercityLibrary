# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class SalesHighlightsController < AdminController
      load_and_authorize_resource class: C::SalesHighlight

      def index; end

      def create
        if @sales_highlight.save
          redirect_to sales_highlights_path, notice: 'Sales Highlight Created'
        else
          render :new
        end
      end

      def update
        if @sales_highlight.update(sales_highlight_params)
          redirect_to sales_highlights_path, notice: 'Sales Highlight Updated'
        else
          render :edit
        end
      end

      def destroy
        @sales_highlight.destroy!
        respond_to do |format|
          format.js
          format.html { redirect_to [:sales_highlights] }
        end
      end

      def confirm_destroy; end

      def sort
        @sales_highlights = C::SalesHighlight.all
        @sales_highlights.update_order(params[:sales_highlight])
        respond_to do |format|
          format.js { head :ok, content_type: 'text/html' }
        end
      end

      private

      def sales_highlight_params
        params.require(:sales_highlight).permit(:image, :url)
      end
    end
  end
end
