# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class OffersController < AdminController
        load_and_authorize_resource class: C::Product::Offer, only: %i[index show]

        def index
          @offers = @offers.ordered
        end

        def show; end
      end
    end
  end
end
