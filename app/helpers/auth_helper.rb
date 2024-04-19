module AuthHelper
  extend self

  UNAUTHORIZED_MSG = "Unauthorized access"

  def log_exception(error, session)
    # #{self.class} -
    Rails.logger.debug "#########################\n"
    Rails.logger.error (["[#{error.class}] #{error.message}: #{session[:previous_url]}", ""]).join("\n")
    Rails.logger.debug "#########################"
  end
end