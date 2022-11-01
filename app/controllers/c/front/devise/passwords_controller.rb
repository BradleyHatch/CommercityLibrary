# frozen_string_literal: true
# rubocop:disable all
module C
  class Front::Devise::PasswordsController < Devise::PasswordsController
    layout 'c/main_application'


    before_action do
      @q ||= C::Product::Variant.ransack(params[:q])
    end
    
  end
end
