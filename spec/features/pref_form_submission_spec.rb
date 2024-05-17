# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require "rails_helper"

RSpec.feature "Preference Form", type: :feature do
  before(:all) do
    staff_email = 'test_staff@sheffield.ac.uk'
    staff = DatabaseHelper.create_staff(staff_email)

    DatabaseHelper.provision_module_class(
      'COM9999',
      'Test Module 1',
      staff
    )

  end
  
  let!(:student) { FactoryBot.create(:standard_student_user, module_code: 'COM9999') }

  context "User cannot see preference form" do
    before(:all) do 
      project = CourseProject.find_or_create_by({
        course_module: CourseModule.find_by(code: 'COM9999'),
        name: 'Test Project 1',
        team_size: 4,
        team_allocation: 'preference_form_based',
        status: :preparation,
        preferred_teammates: 2,
        avoided_teammates: 2
      })
      milestone = Milestone.find_or_create_by({
        course_project_id: project.id,
        system_type: 'teammate_preference_deadline',
        user_generated: true,
        milestone_type: 'for_each_student',
        deadline: "Wed, 15 May 2024 23:30:00.000000000 BST +01:00"
      })
    end

    specify "When project team allocation is not preferenced_team_allocation" do
      login_as student

      visit "projects/1"

      expect(page).to have_content "Teammate Preference Form"
    end
    
    specify "When project status is not in preparation" do
      #login_as student
      #visit "projects/1"
      #expect(page).to have_no_content "Teammate Preference Form"
    end

    specify "When the user has already submitted a response" do
    end
  end

  context "When all criteria are met" do
    specify "User can see the preference form" do
    end

    specify "User can input the correct number of names (preferred and avoided)" do
    end

    specify "User can submit the form" do
    end
  end
end
