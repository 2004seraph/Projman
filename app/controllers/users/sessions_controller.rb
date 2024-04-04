# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
  # def create
  #   super do |user|
  #     if user_signed_in?
  #       # application_controller = ApplicationController.new
  #       # application_controller.load_current_user(user)
  #       username = user.username
  #       account_type = user.account_type

  #       session[:username] = username
  #       sesssion[:account_type] = account_type
  #     end
  #   end
  # end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged our successfully"
  end
  
end
