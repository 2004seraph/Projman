# frozen_string_literal: true

class IssueResponseMailer < ApplicationMailer
  def notify_issue_response(issue_response, issue, recipient_email, group, course_project, course_module)
    @issue = issue
    @issue_response = issue_response
    @recipient_email = recipient_email
    @group = group
    @course_project = course_project
    @course_module = course_module
    @issue_url = "issues#issue-#{issue.id}"
    @url = "#{root_url}#{@issue_url}"
    mail(to: @recipient_email, subject: "[Issue ID - #{@issue.id}] New Issue Response")
  end
end
