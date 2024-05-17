# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require "rails_helper"

RSpec.feature "Submitting Marking", type: :feature do
  let!(:student) { FactoryBot.create(:standard_student_user) }

  before(:all) do
    staff_email = "awillis4@sheffield.ac.uk"
    staff = DatabaseHelper.create_staff(staff_email)

    DatabaseHelper.provision_module_class(
      "COM9999",
      "Test Module 2",
      staff
    )

    project = CourseProject.find_or_create_by({
      course_module:   CourseModule.find_by(code: "COM9999"),
      name:            "Test Project 1",
      team_size:       8,
      team_allocation: :random_team_allocation,
      status:          :live
    })

    # Create a group with 5 random teammates and facilitator
    group = Group.find_or_create_by({
      name:                 "The A Team",
      assigned_facilitator: AssignedFacilitator.find_or_create_by(staff:,
                                                                  course_project: project),
      course_project:       project
    })

    group.students << project.course_module.students[0...5]

    # Create a mark scheme and assign the staff user to it
    milestone = Milestone.new(
      json_data:         JSON.parse({
        sections: [
          {
            title:       "Testing",
            description: "This is a test description.",
            max_marks:   6,
            assessors:   { staff_email => [group.id] }
          }
        ]
      }.to_json),
      deadline:          Date.current.strftime("%Y-%m-%d"),  # Deadline isn't used for mark schemes
      milestone_type:    :team,
      course_project_id: 1,
      system_type:       :marking_deadline
    )
    milestone.save
  end

  describe "Submitting marking as a staff member", js: true do
    before {
      login_as student

      visit "markings/"
    }

    let!(:project_id) { CourseProject.find_by(name: "Test Project 1").id }
    let!(:group) { Group.find_by(name: "The A Team") }

    context "For a section and team I am assigned to" do
      specify "I can submit marking" do
        # Submit marking
        click_link "Test Project 1 - Testing"

        marks_given = "5"
        reasoning = "Reasoning goes here."

        find("#marks-input-1").set marks_given
        find("#reason-input-1").set reasoning
        find("#saveButton").click

        # Verify changes
        click_link "Test Project 1 - Testing"
        expect(find("#marks-input-1").text).to eq(marks_given)
        expect(find("#reason-input-1").text).to eq(reasoning)
      end

      specify "I can edit marking" do
        # Set initial marking
        click_link "Test Project 1 - Testing"

        find("#marks-input-1").set "5"
        find("#reason-input-1").set "Reasoning goes here."
        find("#saveButton").click

        # Edit marking
        click_link "Test Project 1 - Testing"

        find("#marks-input-1").set "3"
        find("#reason-input-1").set "Average"
        find("#saveButton").click

        # Verify changes
        click_link "Test Project 1 - Testing"
        expect(find("#marks-input-1").text).to eq("3")
        expect(find("#reason-input-1").text).to eq("Average")
      end

      specify "I cannot submit marking with invalid marks" do
        # Submit marking
        click_link "Test Project 1 - Testing"

        marks_given = "11" # Marks is above max marks
        reasoning = "Reasoning goes here."

        find("#reason-input-1").set reasoning
        find("#marks-input-1").set marks_given
        find("#saveButton").click

        expect(page).to have_content "Invalid Marks Given"
      end
    end
  end
end
