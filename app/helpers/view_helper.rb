
module ViewHelper
  extend self

  def unparamaterize(str)
    str.tr("_", " ").humanize
  end

  def remove_after_indent(str)
    x = ""
    for i in 0...str.length
      if str[i] == ' '
        return x
      end
      x += str[i]
    end
    x
  end
  def retrieve_courses
    if current_user.staff.admin
      CourseModule.all
    else
      CourseModule.where(staff_id: current_user.staff)
    end
  end
end



















