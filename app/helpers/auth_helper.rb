# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

module AuthHelper
  module_function

  UNAUTHORIZED_MSG = 'Unauthorized access'

  def log_exception(error, session)
    # #{self.class} -
    Rails.logger.debug "#########################\n"
    Rails.logger.error ["[#{error.class}] #{error.message}: #{session[:previous_url]}", ''].join("\n")
    Rails.logger.debug '#########################'
  end
end
