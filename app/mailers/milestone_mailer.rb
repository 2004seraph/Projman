class MilestoneMailer < ApplicationMailer

  def reminder_email(milestone)
    @group_url = "issues#issue-#{issue.id}"
    @url = "#{root_url}#{@issue_url}"

    project = milestone.course_project

    @days_left = milestone.json_data["Email"]["Advance"]

    @time_remaining = @days_left +
      if @days_left == 1
        "day"
      else
        "days"
      end

    mail(to: recipient_email, subject: "[Reminder] #{project.course_module.code} - #{project.name}: #{milestone.json_data["Name"]}, due in #{@time_remaining}")
  end
end
