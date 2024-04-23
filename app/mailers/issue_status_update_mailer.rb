class IssueStatusUpdateMailer < ApplicationMailer
  def notify_status_update(issue, recipient_email, group, course_project, course_module, status)
    @issue = issue
    @recipient_email = recipient_email
    @group = group
    @course_project = course_project
    @course_module = course_module
    @status = status
    mail(to: @recipient_email, subject: "[Issue ID - #{@issue.id}] Issue has been #{status}")
  end
end
