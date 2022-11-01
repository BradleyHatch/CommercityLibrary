# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    class UsersController < AdminController
      load_and_authorize_resource class: C::User

      def index
        @users = filter_and_paginate(@users, 'name asc')
      end

      def create
        if @user.save
          redirect_to users_path, notice: 'User created'
        else
          render :new
        end
      end

      def update
        if @user.update(user_params)
          redirect_to users_path, notice: 'User created'
        else
          render :edit
        end
      end

      def destroy
        if @user != current_user && @user.destroy
          respond_to do |format|
            format.js
            format.html { redirect_to [:redirect] }
          end
        else
          redirect_to [:redirect]
        end
      end

      def confirm_destroy; end

      private

      def user_params
        if params[:user][:password].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end
        params.require(:user).permit(:name, :email, :password, role_ids: [])
      end
    end
  end
end
