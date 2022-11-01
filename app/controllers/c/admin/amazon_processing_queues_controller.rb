# frozen_string_literal: true

require_dependency 'c/application_controller'

module C
  module Admin
    class AmazonProcessingQueuesController < AdminController
      load_and_authorize_resource class: C::AmazonProcessingQueue

      def index
        @amazon_processing_queues = @amazon_processing_queues
                                    .where.not(feed_type: :inventory)
                                    .order(submitted_at: :desc)
                                    .includes(:products)
                                    .paginate(page: params[:page],
                                              per_page: 25)
      end

      def all
        @amazon_processing_queues = @amazon_processing_queues
                                    .order(submitted_at: :desc)
                                    .includes(:products)
                                    .paginate(page: params[:page],
                                              per_page: 25)
        render :index
      end

      def latest
        @amazon_processing_queue = @amazon_processing_queues
                                   .where(feed_type: :product)
                                   .order(submitted_at: :asc).last
        render :show
      end
    end
  end
end
