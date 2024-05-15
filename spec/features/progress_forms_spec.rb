# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require 'rails_helper'

RSpec.feature 'Managing Progress Forms', type: :feature do
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

  describe 'Managing progress forms as a module lead', js: true do
    before { login_as user }
    let!(:project_id) {CourseProject.find_by(name: 'Test Project 1').id}

    context "Creating a new progress form" do 
      before {
        # Start creating a new progress form
        visit "projects/#{project_id}/progress_form/new" 

        # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
        # TODO: I assume this is better than using sleep?
        page.execute_script("document.getElementById('add-question-modal').classList.remove('fade');")
      
      }

      specify "I can create a progress form" do
        # Add a question
        click_button "create-question-button"
        fill_in 'question', with: 'How are you today?'
        click_button "commit"

        # Set release date      
        release_date = DateTime.current      
        find("#release-date-input").set(release_date)

        find("#save-button").click
      
        # Check we've changed page
        expect(page).to have_current_path("/projects/#{project_id}/progress_form")
        find("#release-date-selection-button").click

        # Check the dropdown has automatically selected the newly created progress fom
        selected_release_date = find('#release-date-selection-label').text

        expect(selected_release_date).to  eq("Release Date: " + release_date.strftime("%d/%m/%Y %H:%M"))
      end

      specify "I cannot create a progress form without setting a release date" do 
        # Add a question
        click_button "create-question-button"
        fill_in 'question', with: 'How are you today?'
        click_button "commit"

        find("#save-button").click
      
        expect(page).to have_content("Must set a release date")
      end

      specify "I cannot create a progress form with no questions" do 
        # Set release date      
        release_date = DateTime.current      
        find("#release-date-input").set(release_date)

        find("#save-button").click
        
        expect(page).to have_content("Must add a question")
      end
    end
    
    context "Before an existing progress form is released" do 
      before do
        # Create a progress form that will be released tomorrow
        tomorrow = (DateTime.current + 1).strftime("%d/%m/%Y %H:%M")

        Milestone.new(
          json_data: JSON.parse({
              "questions": ["How are you today?"],
              "attendance": true,
              "name": "progress_form"
            }.to_json),
          deadline: tomorrow,
          milestone_type: :team,
          course_project_id: project_id
        ).save
      end

      let!(:m_id) { Milestone.select{|m| m.json_data["name"] == "progress_form"}.first.id }

      specify "I can edit a progress form" do
        visit "projects/#{project_id}/progress_form/#{m_id}/edit"

        # Hack to remove fade animation from modal as this breaks the tests due to it taking a long time, 
        # TODO: I assume this is better than using sleep?
        page.execute_script("document.getElementById('add-question-modal').classList.remove('fade');")

        # Add a question
        new_question = 'New question'
        click_button "create-question-button"
        fill_in 'question', with: new_question
        click_button "commit"

        # Save the changes
        find("#save-button").click

        # Check page has changed
        expect(page).to have_current_path("/projects/#{project_id}/progress_form")
        find("#release-date-selection-button").click

        expect(page).to have_content(new_question)
      end

      specify "I can delete a progress form" do 
        visit "projects/#{project_id}/progress_form/#{m_id}/edit"

        find("#delete-button").click

        expect(page).to have_current_path("/projects/#{project_id}/progress_form")
        expect(page).to have_content("No progress forms found for this project")
      end

    end

    context "After an existing progress form is released" do 
      before do
        # Create a progress form that was released yesterday
        yesterday = (DateTime.current - 1).strftime("%d/%m/%Y %H:%M")

        Milestone.new(
          json_data: JSON.parse({
              "questions": ["How are you today?"],
              "attendance": true,
              "name": "progress_form"
            }.to_json),
          deadline: yesterday,
          milestone_type: :team,
          course_project_id: project_id
        ).save
      end

      let!(:m_id) { Milestone.select{|m| m.json_data["name"] == "progress_form"}.first.id }

      specify "I cannot edit a released progress form" do 
        visit "projects/#{project_id}/progress_form/#{m_id}/edit"

        expect(page).to have_content("Cannot edit a released form.")
      end      
    end
  end

  describe 'Submitting progress forms as a facilitator', js: true do 
    before { 
      login_as user 

      visit "facilitators/"

      # Create a progress form that was released yesterday
      yesterday = (DateTime.current - 1).strftime("%d/%m/%Y %H:%M")

      Milestone.new(
        json_data: JSON.parse({
            "questions": ["How are you today?"],
            "attendance": true,
            "name": "progress_form"
          }.to_json),
        deadline: yesterday,
        milestone_type: :team,
        course_project_id: project_id
      ).save

    }

    let!(:project_id) { CourseProject.find_by(name: 'Test Project 1').id }
    let!(:group) { Group.find_by(name: 'The A Team') }

    specify "I can fill in a progress form for a team I'm assigned to" do 
      # Go to the team page for the first assigned team
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Go to the first released progress form
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      # Take attendance
      attendance_checkboxes = all('input[type="checkbox"].absent-checkbox')
      attendance_checkboxes[0].check
      attendance_checkboxes[1].check

      reason_inputs = all('input[type="text"].absent-reason-input')
      reason_inputs[0].set("Sick")
      reason_inputs[1].set("Holiday")
      
      # Answer the question
      find('textarea.form-control.question-textarea').set("Good thank you!")
      
      # Submit response
      find('#saveButton').click

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Re-open the progress form to check the response has loaded
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end
      
      expect(page).to have_content("Last updated by: " + user.email)
    end

    specify "I can fill in a progress form for a team I'm not assigned to" do 
      # Remove the team's facilitator temporarily
      group.assigned_facilitator = nil
      group.save

      visit "facilitators/"

      # Show non-assigned teams
      uncheck "filter-checkbox"

      # Click the unassigned team
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Go to the first released progress form
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end
      
      # Take attendance
      attendance_checkboxes = all('input[type="checkbox"].absent-checkbox')
      attendance_checkboxes[0].check
      attendance_checkboxes[1].check

      reason_inputs = all('input[type="text"].absent-reason-input')
      reason_inputs[0].set("Sick")
      reason_inputs[1].set("Holiday")
      
      # Answer the question
      find('textarea.form-control.question-textarea').set("Good thank you!")
      
      # Submit response
      find('#saveButton').click

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Re-open the progress form to check the response has loaded
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      expect(page).to have_content("Last updated by: " + user.email)      
    end

    specify "I can edit a progress form response" do 
      # Go to the team page for the first assigned team
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Go to the first released progress form
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end

      # Take attendance
      attendance_checkboxes = all('input[type="checkbox"].absent-checkbox')
      attendance_checkboxes[0].check
      attendance_checkboxes[1].check

      reason_inputs = all('input[type="text"].absent-reason-input')
      reason_inputs[0].set("Sick")
      reason_inputs[1].set("Holiday")
      
      # Answer the question
      find('textarea.form-control.question-textarea').set("Good thank you!")
      
      # Submit response
      find('#saveButton').click

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Re-open the progress form to check the response has loaded
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end
      
      expect(page).to have_content("Last updated by: " + user.email)

      # Edit the response
      find('textarea.form-control.question-textarea').set("Decent thank you!")

      # Submit response
      find('#saveButton').click

      # Open the progress forms card
      find('#progress-forms-card-header').click

      # Re-open the progress form to check the response has loaded
      within('div.navigation-list-item', match: :first) do 
        first('a').click
      end
      
      expect(page).to have_content("Decent thank you!")
    end
  end 

  describe 'Viewing progress forms responses', js: true do
    before { 
      login_as user 

      # Create a progress form that was released yesterday
      yesterday = (DateTime.current - 1).strftime("%d/%m/%Y %H:%M")

      milestone = Milestone.new(
        json_data: JSON.parse({
            "questions": ["How are you today?", "What is the time?"],
            "attendance": true,
            "name": "progress_form"
          }.to_json),
        deadline: yesterday,
        milestone_type: :team,
        course_project_id: project_id
      )
      milestone.save

      MilestoneResponse.new(
        json_data: {
          group_id: Group.find_by(name: 'The A Team').id,
          attendance: [[true, ""], [false, "reason1"], [false, "reason2"], [false, "reason3"], [true, ""]],
          question_responses: ["Good!", "Idk."],
          facilitator_repr: "awillis4@sheffield.ac.uk"
        },
        milestone_id: milestone.id
      ).save

      visit "projects/1/progress_form/"
    }

    let!(:project_id) { CourseProject.find_by(name: 'Test Project 1').id }
    let!(:group) { Group.find_by(name: 'The A Team') }


    specify "I can view a progress form response" do
      find("#team-selection-button").click
      
      # Get all team dropdown links
      dropdown_links = all('div.dropdown-menu a')

      # Click the last one
      dropdown_links.last.click

      # Verify questions and response
      expect(page).to have_content("Last updated by: " + user.email)
      expect(page).to have_content("Good!")
      expect(page).to have_content("Idk.")

      # Verify attendance
      attendance_checkboxes = all('input[type="checkbox"].absent-checkbox')
      reason_inputs = all('input[type="text"].absent-reason-input')

      expect(page).to have_checked_field(attendance_checkboxes[0][:id])

      expect(page).to have_unchecked_field(attendance_checkboxes[1][:id])
      expect(page).to have_field(reason_inputs[0][:id], with: 'reason1')

      expect(page).to have_unchecked_field(attendance_checkboxes[2][:id])
      expect(page).to have_field(reason_inputs[1][:id], with: 'reason2')

      expect(page).to have_unchecked_field(attendance_checkboxes[3][:id])
      expect(page).to have_field(reason_inputs[2][:id], with: 'reason3')

      expect(page).to have_checked_field(attendance_checkboxes[4][:id])
    end
  end


end
