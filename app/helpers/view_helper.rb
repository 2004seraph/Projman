# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

module ViewHelper
  module_function

  def unparamaterize(str)
    str.tr('_', ' ').humanize
  end

  def remove_after_indent(str)
    x = ''
    (0...str.length).each do |i|
      return x if str[i] == ' '

      x += str[i]
    end
    x
  end

  def retrieve_courses
    return [] unless current_user.is_staff?
    return CourseModule.all if current_user.staff.admin

    CourseModule.where(staff_id: current_user.staff)
  end

  def get_module_code(code)
    session[:module_data] = {} if session[:module_data].nil?
    session[:module_data][:module_code] = code
  end

  def set_session_module_code(code)
    session[:module_data] = {} if session[:module_data].nil?
    session[:module_data][:module_code] = code
  end
end
