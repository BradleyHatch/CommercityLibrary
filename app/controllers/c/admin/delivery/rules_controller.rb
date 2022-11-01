# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Delivery
      class RulesController < AdminController
        load_and_authorize_resource class: C::Delivery::Rule
        before_action :set_service

        def create
          if @rule.save
            redirect_to edit_delivery_service_path(@service.id),
                        notice: 'Rule Created'
          else
            render :new
          end
        end

        def edit; end

        def update
          if @rule.update(rule_params)
            redirect_to edit_delivery_service_path(@service.id),
                        notice: 'Rule Updated'
          else
            render :edit
          end
        end

        def destroy
          @rule.destroy
          redirect_to edit_delivery_service_path(@service.id),
                      notice: 'Rule Deleted'
        end

        private

        def rule_params
          params.require(:delivery_rule).permit(:zone_id,
                                                :base_price,
                                                :min_cart_price_pennies,
                                                :max_cart_price_pennies,
                                                gaps_attributes: %i[id
                                                                    lower_bound
                                                                    cost
                                                                    _destroy])
        end

        def set_service
          @service = @rule.service
        end
      end
    end
  end
end
