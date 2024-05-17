# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MessageMailer < ApplicationMailer
  def individual_message(staff, recipient_email, subject, body, project = nil)
    @student = Student.find_by(email: recipient_email)
    return false unless @student

    @body_text = body

    @staff_name = "#{staff.givenname} #{staff.sn}"

    if project != nil
      path = "projects/#{project.id}"
      @project_url = "#{root_url}#{path}"
    end

    mail(
      to:      @student.email,
      subject: "[Message from #{@staff_name}] #{subject}"
    )
  end
end
