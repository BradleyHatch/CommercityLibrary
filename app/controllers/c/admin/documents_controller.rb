# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class DocumentsController < AdminController
      load_and_authorize_resource class: C::Document

      def index; end

      def create
        if @document.save
          redirect_to documents_path, notice: 'Document created'
        else
          render :new
        end
      end

      def update
        if @document.update(document_params)
          redirect_to documents_path, notice: 'Document updated'
        else
          render :edit
        end
      end

      def destroy
        @document.destroy
        redirect_to documents_path, notice: 'Document deleted'
      end

      def bulk_upload
        if (documents = params[:documents])
          count = Document.bulk_upload(documents[:attachments])
          redirect_to documents_path, notice: "Uploaded #{count} Documents"
        else
          redirect_to new_document_path, notice: 'No file chosen'
        end
      end

      private

      def document_params
        params.require(:document).permit(:document, :name)
      end
    end
  end
end
