# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require 'auth_helper'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  check_authorization unless: :devise_controller?

  # Disabling caching will prevent sensitive information being stored in the
  # browser cache. If your app does not deal with sensitive information then it
  # may be worth enabling caching for performance.
  before_action :update_headers_to_disable_caching
  before_action :authenticate_user!
  before_action :load_current_user

  before_action :store_location, unless: :devise_controller?
  def store_location
    return unless user_initiated_page_request? && request.path != '/users/sign_in'

    session[:redirect_url] = session[:previous_url]
    session[:previous_url] = request.fullpath
  end

  rescue_from CanCan::AccessDenied do |exception|
    # gracefully redirect the user to the previous page they were on
    AuthHelper.log_exception exception, session

    if user_initiated_page_request?
      redirect_to session[:redirect_url], alert: AuthHelper::UNAUTHORIZED_MSG
    else
      # fail fast if it was not a get request
      throw exception
    end
  end

  def user_initiated_page_request?
    !request.xhr? && request.request_method_symbol == :get
  end

  def load_current_user
    return unless user_signed_in?

    username = current_user.username
    # if current_user.respond_to? :username
    #   current_user.username
    # else
    #   if current_user
    # end
    # current_user.account_type

    if current_user.is_student? && Student.exists?(username:)
      current_user.student = Student.find_by(username:)
      # email = current_user.student.email
      # # Also populate the staff field if this student has a staff entry
      # current_user.staff = Staff.find_by(email:) if Staff.exists?(email:)
      # else
      #   reset_session
      #   redirect_to new_user_session_path, alert: AuthHelper::UNAUTHORIZED_MSG
    end
    current_user.staff = Staff.find_or_create_by(email: current_user.email) if current_user.is_staff?

    return if current_user.is_staff? || current_user.is_student?

    reset_session
    redirect_to new_user_session_path, alert: AuthHelper::UNAUTHORIZED_MSG
  end

  private

  def update_headers_to_disable_caching
    response.headers['Cache-Control'] = 'no-cache, no-cache="set-cookie", no-store, private, proxy-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '-1'
  end
end
