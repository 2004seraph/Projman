class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # check_authorization unless: :devise_controller?

  # Disabling caching will prevent sensitive information being stored in the
  # browser cache. If your app does not deal with sensitive information then it
  # may be worth enabling caching for performance.
  before_action :update_headers_to_disable_caching
  before_action :authenticate_user!
  before_action :load_current_user

  # before_action :store_current_location, :unless => :devise_controller?
  # def store_current_location
  #   store_location_for(:user, request.url)
  # end
  # rescue_from CanCan::AccessDenied do |exception|
  #   Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

  #   # session["user_return_to"] = request.fullpath
  #   redirect_to new_user_session_path, alert: "#{exception.message}"
  # end

  def load_current_user
    if user_signed_in?
      username = current_user.username
      account_type = current_user.account_type
      email = current_user.email

      if current_user.is_student?
        if Student.exists?(username: username)
          current_user.student = Student.find_by(username: username)
          # Also populate the staff field if this student has a staff entry
          if Staff.exists?(email: email)
            current_user.staff = Staff.find_by(email: email)
          end
        else
          reset_session
          redirect_to new_user_session_path, alert: "User not found in the database. Please try again."
        end
      elsif current_user.is_staff?
        current_user.staff = Staff.find_or_create_by(email: email)
      else
        reset_session
        redirect_to new_user_session_path, alert: "Unauthorised access."
      end
    end
  end

  private
    def update_headers_to_disable_caching
      response.headers['Cache-Control'] = 'no-cache, no-cache="set-cookie", no-store, private, proxy-revalidate'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '-1'
    end

end
