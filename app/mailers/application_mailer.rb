# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@sheffield.ac.uk'
  layout 'mailer'
end
