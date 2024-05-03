# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class StudentController < ApplicationController
  # load_and_authorize_resource
  skip_authorization_check
  helper_method :update_selection

  def index
    return unless session[:current_selection].nil?

    session[:current_selection] = ['current selection']
  end

  def update_selection
    Rails.logger.debug '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    Rails.logger.debug @text_value
    session[:current_selection] << 'input_text' # Need to get data from text box, and confirm there is a student not in that module.
    Rails.logger.debug session[:current_selection]
    # send updated current_selection back to the view.
  end
  #     def confirm_selection
  #         puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  #     end
  # def remove_students
  # end
end
