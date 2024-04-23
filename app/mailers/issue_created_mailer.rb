class IssueCreatedMailer < ApplicationMailer
  def notify_issue_created(issue, module_lead_email, group, course_project, course_module)
    @issue = issue
    @module_lead_email = module_lead_email
    @group = group
    @course_project = course_project
    @course_module = course_module
    mail(to: @module_lead_email, subject: "[Issue ID - #{@issue.id}] New Issue Reported")
  end
end
