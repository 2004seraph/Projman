class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Disabling caching will prevent sensitive information being stored in the
  # browser cache. If your app does not deal with sensitive information then it
  # may be worth enabling caching for performance.
  before_action :update_headers_to_disable_caching
  before_action :authenticate_user!
  before_action :load_current_user

  def load_current_user
    if user_signed_in?
      username = current_user.username
      account_type = current_user.account_type

      if account_type.include?("student")
        if Student.exists?(username: username)
          @user = Student.find_by(username: username)
          if Staff.exists?(email: @user.email)
            # this should be CanCanCan stuff, not a manual boolean
            # @is_staff = true
          end
        else
          reset_session
          redirect_to new_user_session_path, alert: "User not found in the database. Please try again."
        end
      elsif account_type.include?("staff")
        @user = Staff.find_by(email: current_user.email)
        # this should be CanCanCan stuff, not a manual boolean
        # @is_staff = true
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
