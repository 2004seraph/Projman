# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class IssueCreatedMailer < ApplicationMailer
  def notify_issue_created(issue, module_lead_email, group, course_project, course_module)
    @issue = issue
    @module_lead_email = module_lead_email
    @group = group
    @course_project = course_project
    @course_module = course_module
    @issue_url = "issues#issue-#{issue.id}"
    @url = "#{root_url}#{@issue_url}"
    mail(to: @module_lead_email, subject: "[Issue ID - #{@issue.id}] New Issue Reported")
  end
end
