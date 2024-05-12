# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require "rails_helper"

describe "Preference Form Submission" do
  let!(:student_user) { FactoryBot.create(:standard_student_user) }

  DatabaseHelper.create_staff("jbala1@sheffield.ac.uk")
  DatabaseHelper.provision_module_class(
    "COM9999",
    "Test Module 1",
    Staff.find_by(email: "jbala1@sheffield.ac.uk")
  )
  Student.find_or_create_by(email: "awillis4@sheffield.ac.uk").enroll_module "COM9999"

  before { login_as student_user }

  context "User cannot see preference form" do
    specify "When project team allocation is not preferenced_team_allocation" do
      CourseProject.find_or_create_by({
        course_module:   CourseModule.find_by(code: "COM9999"),
        name:            "Test Project 1",
        # project_allocation: :single_preference_project_allocation,
        status:          :preparation,
        team_allocation: :random_team_allocation,
        team_size:       8
      })

      visit "projects"
      click_on "COM9999 Test Module 1 - Test Project 1"

      expect(page).to have_no_content "Teammate Preference Form"
    end

    specify "When project status is not in preparation" do
    end

    specify "When the user has already submitted a response" do
    end
  end

  context "When all three criteria are met"

  specify "User can see the preference form" do
  end

  specify "User can input the correct number of names (preferred and avoided)" do
  end

  specify "User can submit the form" do
  end
end
