# frozen_string_literal: true

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
end
