# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require 'rails_helper'

RSpec.feature 'Managing Mark Schemes', type: :feature do
  let!(:user) { FactoryBot.create(:standard_student_user) }
  let!(:student) { FactoryBot.create(:standard_student) } # without this line, cant log in?
  let!(:staff) { Staff.find_or_create_by(email: user.email) }

  before(:all) do
    staff_email = 'awillis4@sheffield.ac.uk'
    staff = DatabaseHelper.create_staff(staff_email)
    
    DatabaseHelper.provision_module_class(
      'COM9999',
      'Test Module 2',
      staff
    )

    project = CourseProject.find_or_create_by({
      course_module: CourseModule.find_by(code: 'COM9999'),
      name: 'Test Project 1',
      team_size: 8,
      team_allocation: :random_team_allocation,
      status: :live
    })

    # Create a group with 5 random teammates and facilitator
    group = Group.find_or_create_by({
      name: 'The A Team',
      assigned_facilitator: AssignedFacilitator.find_or_create_by(staff: staff,
        course_project: project),
      course_project: project
    })

    group.students << project.course_module.students[0...5]
  end

  describe 'Managing mark schemes as a module lead', js: true do
    before { 
      login_as user 

      visit "projects/1/mark_scheme/"
    }

    let!(:project_id) { CourseProject.find_by(name: 'Test Project 1').id }
    let!(:group) { Group.find_by(name: 'The A Team') }

    specify "I can create a mark scheme" do
      find('#new-mark-scheme-button').click
      
      # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
      # TODO: I assume this is better than using sleep?
      page.execute_script("document.getElementById('add-section-modal').classList.remove('fade');")

      # Create a new section
      find('#create-section-button').click
      find('#section-title-text-area').set 'Testing'
      click_button "Add"

      # Set the max marks and description
      max_marks = "5"
      description = "This section is about testing."

      find('#maximum-marks-input-0').set max_marks
      find('#description-textarea-0').set description

      # Try save
      find('#save-button').click

      # Click the view/edit button
      find('#new-mark-scheme-button').click

      # Check the values have been set correctly
      expect(find('#maximum-marks-input-0').value).to eq(max_marks)
      expect(find('#description-textarea-0').value).to eq(description)
    end

    specify "I can edit an existing mark scheme" do
      # Create a mark scheme with dummy data to edit
      milestone = Milestone.new(
        json_data: JSON.parse({ 
          sections: [
            {
              title: "Testing", 
              description: 'This is a test description.', 
              max_marks: 6 
            }
          ] 
        }.to_json),
        deadline: Date.current.strftime('%Y-%m-%d'),  # Deadline isn't used for mark schemes
        milestone_type: :team,                        
        course_project_id: 1,
        system_type: :marking_deadline
      ).save

      find('#new-mark-scheme-button').click
      
      # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
      # TODO: I assume this is better than using sleep?
      page.execute_script("document.getElementById('add-section-modal').classList.remove('fade');")
            
      # Delete existing section
      find("#delete-section-0").click

      # Create a new section
      find('#create-section-button').click
      find('#section-title-text-area').set 'Testing'
      click_button "Add"

      # Set the max marks and description
      max_marks = "5"
      description = "This section is about testing."

      find('#maximum-marks-input-0').set max_marks
      find('#description-textarea-0').set description
      
      # Try save
      find('#save-button').click

      # Click the view/edit button
      find('#new-mark-scheme-button').click

      # Check the values have been set correctly
      expect(find('#maximum-marks-input-0').value).to eq(max_marks)
      expect(find('#description-textarea-0').value).to eq(description)
    end

    specify "I can export an existing mark scheme" do 
      # Create a mark scheme
      milestone = Milestone.new(
        json_data: JSON.parse({ 
          sections: [
            {
              title: "Testing", 
              description: 'This is a test description.', 
              max_marks: 6 
            }
          ] 
        }.to_json),
        deadline: Date.current.strftime('%Y-%m-%d'),  # Deadline isn't used for mark schemes
        milestone_type: :team,                        
        course_project_id: 1,
        system_type: :marking_deadline
      )
      milestone.save

      # Create a mark scheme response
      mresponse = MilestoneResponse.new(
        json_data: {
          "sections": {
            "Testing" => {
              'marks_given' => "6",
              'reason' => "Good testing.",
              'assessor' => user.email
            }
          },
          "group_id": group.id
        },
        milestone_id: milestone.id
      ).save

      # Refresh page, normally wouldn't need to but because we're just using modal we do
      visit "projects/1/mark_scheme/"
      
      find("#export-button").click

      # TODO: Check a csv is downloaded as an attachment.
    end

    specify "I can import a mark scheme csv with a correctly formatted csv" do 
      # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
      # TODO: I assume this is better than using sleep?
      page.execute_script("document.getElementById('import-mark-scheme-modal').classList.remove('fade');")

      find("#import-mark-scheme-button").click

      csv_data = "Title1,Description1,15\nTitle2,Description2,0\nTitle3,Description3,1\nTitle4,Description4,6"
      csv_file = Tempfile.new(['example', '.csv'])
      csv_file.write(csv_data)
      csv_file.close

      find('#mark-scheme-input', visible: false).set(csv_file.path)

      click_button "Import"

      # Click the view/edit button
      find('#new-mark-scheme-button').click

      # Check the values have been set correctly
      expect(find('#maximum-marks-input-0').value).to eq("15")
      expect(find('#description-textarea-0').value).to eq("Description1")

      expect(find('#maximum-marks-input-1').value).to eq("0")
      expect(find('#description-textarea-1').value).to eq("Description2")

      expect(find('#maximum-marks-input-2').value).to eq("1")
      expect(find('#description-textarea-2').value).to eq("Description3")

      expect(find('#maximum-marks-input-3').value).to eq("6")
      expect(find('#description-textarea-3').value).to eq("Description4")
    end

    specify "I cannot import a mark scheme csv with an incorrectly formatted csv" do 
      # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
      # TODO: I assume this is better than using sleep?
      page.execute_script("document.getElementById('import-mark-scheme-modal').classList.remove('fade');")

      find("#import-mark-scheme-button").click

      csv_data = "invalid,format,invalid,format"
      csv_file = Tempfile.new(['example', '.csv'])
      csv_file.write(csv_data)
      csv_file.close

      find('#mark-scheme-input', visible: false).set(csv_file.path)

      click_button "Import"

      expect(page).to have_content("Invalid CSV format.")
    end

    specify "I can assign a staff member to a section of the mark scheme for teams" do 
      # Create a mark scheme with dummy data to edit
      Milestone.new(
        json_data: JSON.parse({ 
          sections: [
            {
              title: "Testing", 
              description: 'This is a test description.', 
              max_marks: 6 
            }
          ] 
        }.to_json),
        deadline: Date.current.strftime('%Y-%m-%d'),  # Deadline isn't used for mark schemes
        milestone_type: :team,                        
        course_project_id: 1,
        system_type: :marking_deadline
      ).save
      
      visit "projects/1/mark_scheme/"
      
      # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
      # TODO: I assume this is better than using sleep?
      page.execute_script("document.getElementById('add-assessor-to-section-modal').classList.remove('fade');")
      page.execute_script("document.getElementById('assign-teams-modal').classList.remove('fade');")

      find("#add-assessor-to-section").click
      find("#add-assessor-to-section-form").set "awillis4@sheffield.ac.uk"
      click_button "Add"
      click_button "Confirm"
      
      visit "projects/1/mark_scheme/" # Refresh the page, this is instead of sleeping!
      click_button "Auto Assign"
      visit "projects/1/mark_scheme/" # Refresh the page, this is instead of sleeping!

      expect(page).to have_content('The A Team')
    end

    specify "I can view the submitted marks for a team" do
      # Create a mark scheme with dummy data to edit
      milestone = Milestone.new(
        json_data: JSON.parse({ 
          sections: [
            {
              title: "Testing", 
              description: 'This is a test description.', 
              max_marks: 6 
            }
          ] 
        }.to_json),
        deadline: Date.current.strftime('%Y-%m-%d'),  # Deadline isn't used for mark schemes
        milestone_type: :team,                        
        course_project_id: 1,
        system_type: :marking_deadline
      )
      milestone.save

      response = MilestoneResponse.new(
        json_data: {
          "sections": {
            'Testing' => {
              'marks_given' => 5,
              'reason' => 'This team did well.',
              'assessor' => user.email
            }
          },
          "group_id": group.id
        },
        milestone_id: milestone.id
      )
      response.save

      find("#view-marks-button").click
      find("#team-selection-button").click
      
      # Get all team dropdown links
      dropdown_links = all('div.dropdown-menu a')

      # Click the last one
      dropdown_links.last.click

      # Check for the marking data
      expect(page).to have_content "5"
      expect(page).to have_content "This team did well."
      expect(page).to have_content "awillis4@sheffield.ac.uk"
    end
  end
end
