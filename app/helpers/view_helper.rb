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
    if current_user.is_staff?
      if current_user.staff.admin
        return CourseModule.all
      else
        return CourseModule.where(staff_id: current_user.staff)
      end
    else
      return []
    end
  end
end
