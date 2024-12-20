# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class IssueStatusUpdateMailer < ApplicationMailer
  def notify_status_update(issue, recipient_email, group, course_project, course_module, status)
    @issue = issue
    @recipient_email = recipient_email
    @group = group
    @course_project = course_project
    @course_module = course_module
    @status = status
    @issue_url = "issues#issue-#{issue.id}"
    @url = "#{root_url}#{@issue_url}"
    mail(to: @recipient_email, subject: "[Issue ID - #{@issue.id}] Issue has been #{status}")
  end
end
