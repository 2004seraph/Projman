class MilestoneMailer < ApplicationMailer

  def reminder_email(milestone)
    @project = milestone.course_project

    @days_left = milestone.json_data["Email"]["Advance"]
    @date = milestone.deadline
    @time_remaining = @days_left.to_s +
      if @days_left.to_i == 1
        "day"
      else
        "days"
      end

    @milestone_name = milestone.json_data["Name"] || "Project milestone"
    @milestone_comment = milestone.json_data["Comment"] || ""

    @project_url = "projects/#{@project.id}"
    @url = "#{root_url}#{@project_url}"

    @project.students.each do |s|
      mail(
        to: s.email,
        subject: "[Reminder] #{@project.course_module.code} - #{@project.name}: #{milestone.json_data["Name"]}, due in #{@time_remaining}"
      )
    end
  end
end
