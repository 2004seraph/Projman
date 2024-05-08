# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class ProfileMailer < ApplicationMailer
  def notify_admin_title_change_request(admin_email, user, requested_title)
    @user = user
    @requested_title = requested_title
    mail(to: admin_email, subject: "[UCard Number: #{user.student.ucard_number}] Request Title Change Notification")
  end
end
