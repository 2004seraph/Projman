# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require 'rails_helper'

RSpec.feature 'Project Creation', type: :feature do
  let!(:staff_user) { FactoryBot.create(:standard_staff_user) }

  before(:all) do
    DatabaseHelper.create_staff('awillis4@sheffield.ac.uk')
    DatabaseHelper.create_staff('jbala1@sheffield.ac.uk')
    DatabaseHelper.provision_module_class(
      'COM9999',
      'Test Module 2',
      Staff.find_by(email: 'awillis4@sheffield.ac.uk')
    )
    DatabaseHelper.provision_module_class(
      'COM8888',
      'Test Module 1',
      Staff.find_by(email: 'awillis4@sheffield.ac.uk')
    )
    CourseProject.find_or_create_by({
      course_module:   CourseModule.find_by(code: 'COM8888'),
      name:            'Test Project 1',
      # project_allocation: :single_preference_project_allocation,
      team_allocation: :random_team_allocation,
      team_size:       8
    })

    # Capybara.current_driver = :selenium
  end
  after(:all) do
    # Capybara.current_driver = Capybara.default_driver
  end

  # UX

  describe 'User can toggle Project Choices visibility', js: true do
    context 'when clicking the toggle button' do
      it 'hides the Project Choices panel if it is currently visible' do
        Capybara.ignore_hidden_elements = false

        login_as staff_user
        visit '/projects/new'
        find('#project-choices-enable').uncheck
        expect(page).to have_css('#project-choices .card-body.display-none')

        Capybara.ignore_hidden_elements = true
      end
    end
  end

  describe 'User gets shown deadline for the teammate preference form, and the preference form settings' do
    context 'when they set the team allocation mode to preference form' do
      it 'Shows teammate preference form deadline and settings' do
        login_as staff_user
        visit '/projects/new'
        select('Preference form based', from: 'team_allocation_method')
        expect(page).to have_css('#team-preference-form-settings')
        expect(page).to have_css('#teammate-preference-form-deadline-row')
      end
    end
  end

  describe 'User gets shown deadline for the project preference form' do
  end

  describe 'Creation form gets filled with correct fields' do
    before(:each) do
      login_as staff_user
      visit '/projects/new'
    end
    context 'when the page is first loaded' do
      it 'fills in module options with modules that user is a module lead for' do
        select_element = find("select[name='module_selection']")
        options = select_element.all('option')
        options.each do |option|
          course_module_code = option.value
          course_module = CourseModule.find_by(code: course_module_code)
          expect(course_module.staff_id).to eq(staff.id)
        end
      end
      it 'fills in correct project allocation methods into selection' do
        select_element = find("select[name='project_allocation_method']")
        options = select_element.all('option')
        project_allocation_methods = CourseProject.project_allocations.keys
        options.each do |option|
          expect(project_allocation_methods).to include(option.value)
        end
      end
      it 'fills in correct team allocation methods into selection' do
        select_element = find("select[name='team_allocation_method']")
        options = select_element.all('option')
        team_allocation_methods = CourseProject.team_allocations.keys
        options.each do |option|
          expect(team_allocation_methods).to include(option.value)
        end
      end
    end
    context 'when the page is reloaded on a failed submission' do
      it 'fills in module options with modules that user is a module lead for' do
        click_button 'create-project-save-button'
        select_element = find("select[name='module_selection']")
        options = select_element.all('option')
        options.each do |option|
          course_module_code = option.value
          course_module = CourseModule.find_by(code: course_module_code)
          expect(course_module.staff_id).to eq(staff.id)
        end
      end
      it 'fills in correct project allocation methods into selection' do
        click_button 'create-project-save-button'
        select_element = find("select[name='project_allocation_method']")
        options = select_element.all('option')
        project_allocation_methods = CourseProject.project_allocations.keys
        options.each do |option|
          expect(project_allocation_methods).to include(option.value)
        end
      end
      it 'fills in correct team allocation methods into selection' do
        click_button 'create-project-save-button'
        select_element = find("select[name='team_allocation_method']")
        options = select_element.all('option')
        team_allocation_methods = CourseProject.team_allocations.keys
        options.each do |option|
          expect(team_allocation_methods).to include(option.value)
        end
      end
      it 'persists the project name' do
        fill_in 'project_name', with: 'New Project'
        click_button 'create-project-save-button'
        expect(page).to have_field('project_name', with: 'New Project')
      end
      it 'persists the previous selected module' do
        select('COM9999 Test Module 2', from: 'module_selection')
        click_button 'create-project-save-button'
        expect(page).to have_select('module_selection', selected: 'COM9999 Test Module 2')
      end
      it 'persists all added project choices' do
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 1'
          find('.btn-primary', visible: :all).click
          fill_in 'project_choice_name', with: 'Project Choice 2'
          find('.btn-primary', visible: :all).click
        end
        click_button 'create-project-save-button'
        within '#project-choices' do
          expect(page).to have_content('Project Choice 1')
          expect(page).to have_content('Project Choice 2')
        end
      end
      it 'persists the previous selected project allocation method' do
        select('Single preference submission', from: 'project_allocation_method')
        click_button 'create-project-save-button'
        expect(page).to have_select('project_allocation_method', selected: 'Single preference submission')
      end
      it 'persists the previous seleted team allocation method' do
        select('Preference form based', from: 'team_allocation_method')
        click_button 'create-project-save-button'
        expect(page).to have_select('team_allocation_method', selected: 'Preference form based')
      end
      it 'persists set team size' do
        fill_in 'team_size', with: 6
        click_button 'create-project-save-button'
        expect(page).to have_field('team_size', with: '6')
      end
      it 'persists preferred and avoided teammates' do
        fill_in 'preferred_teammates', with: 1
        fill_in 'avoided_teammates', with: 3
        click_button 'create-project-save-button'
        expect(page).to have_field('preferred_teammates', with: '1')
        expect(page).to have_field('avoided_teammates', with: '3')
      end
      it 'persists all deadline data' do
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Teammate Preference Form Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Project Preference Form Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        expect(page).to have_field('milestone_Project Deadline_date', with: '28/06/2099T00:00')
        expect(page).to have_field('milestone_Teammate Preference Form Deadline_date', with: '28/06/2099T00:00')
        expect(page).to have_field('milestone_Project Preference Form Deadline_date', with: '28/06/2099T00:00')
      end
      it 'persists all added milestones' do
        within '#add-project-milestone-modal' do
          fill_in 'project_milestone_name', with: 'New Milestone 1'
          find('.btn-primary', visible: :all).click
          fill_in 'project_milestone_name', with: 'New Milestone 2'
          find('.btn-primary', visible: :all).click
        end
        within '#timings' do
          expect(page).to have_content('New Milestone 1')
          expect(page).to have_content('New Milestone 2')
          fill_in 'milestone_New Milestone 1_date', with: '28/06/2099T00:00'
          fill_in 'milestone_New Milestone 2_date', with: '28/06/2099T00:00'
        end
        click_button 'create-project-save-button'
        within '#timings' do
          expect(page).to have_content('New Milestone 1')
          expect(page).to have_content('New Milestone 2')
          expect(page).to have_field('milestone_New Milestone 1_date', with: '28/06/2099T00:00')
          expect(page).to have_field('milestone_New Milestone 2_date', with: '28/06/2099T00:00')
        end
      end
      it 'persists all added facilitators' do
        within '#add-staff-project-facilitators-modal' do
          fill_in 'project_facilitator_name', with: 'awillis4@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          fill_in 'project_facilitator_name', with: 'jbala1@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          find('.btn-primary', visible: :all).click
        end
        within '#project-facilitators' do
          expect(page).to have_content('awillis4@sheffield.ac.uk')
          expect(page).to have_content('jbala1@sheffield.ac.u')
        end
        click_button 'create-project-save-button'
        within '#project-facilitators' do
          expect(page).to have_content('awillis4@sheffield.ac.uk')
          expect(page).to have_content('jbala1@sheffield.ac.u')
        end
      end
    end
  end

  # INVALID SUBMISSIONS

  describe 'User tries to create a new project with invalid parameters' do
    before(:each) do
      login_as staff_user
      visit '/projects/new'
    end
    after(:each) do
      expect(page.current_path).to eq('/projects/new')
    end
    context 'Project Name is left empty' do
      it 'shows error' do
        click_button 'create-project-save-button'
        expect(page).to have_text('Project name cannot be empty')
      end
    end
    context 'Project Name is taken by another on the module' do
      it 'shows error' do
        fill_in 'project_name', with: 'Test Project 1'
        select('COM8888 Test Module 1', from: 'module_selection')
        click_button 'create-project-save-button'
        expect(page).to have_text('There exists a project on this module with the same name')
      end
    end
    context 'Module is invalid' do
      it 'shows error' do
        # Requires JS
      end
    end
    context 'Project choices enabled but none given' do
      it 'shows error' do
        click_button 'create-project-save-button'
        expect(page).to have_text('Add at least 2 project choices, or disable this section')
      end
    end
    context 'Project Allocation method is invalid' do
      it 'shows error' do
        # Requires JS
      end
    end
    context 'Team size is invalid' do
      it 'shows error' do
        # Requires JS
      end
    end
    context 'Teammate Preference form has both fields as 0' do
      it 'shows error' do
        select('Preference form based', from: 'team_allocation_method')
        fill_in 'project_name', with: 'New Project'
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Teammate Preference Form Deadline_date', with: '28/06/2099T00:00'
        fill_in 'preferred_teammates', with: 0
        fill_in 'avoided_teammates', with: 0
        click_button 'create-project-save-button'
        expect(page).to have_text('Preferred and Avoided teammates cannot both be 0')
      end
    end
    context 'Team allocation mode is invalid' do
      it 'shows error' do
        # Requires JS
      end
    end
    context 'Project deadline not set' do
      it 'shows error' do
        click_button 'create-project-save-button'
        expect(page).to have_text('Please set project deadline')
      end
    end
    context 'Teammate preference form deadline not set' do
      it 'shows error' do
        select('Preference form based', from: 'team_allocation_method')
        click_button 'create-project-save-button'
        expect(page).to have_text('Please set team preference form deadline')
      end
    end
    context 'Project preference form deadline not set' do
      it 'shows error' do
        select('Team average preference', from: 'project_allocation_method')
        click_button 'create-project-save-button'
        expect(page).to have_text('Please set project preference form deadline')
      end
    end
    context 'milestone dates left unset' do
      it 'shows error' do
        within '#add-project-milestone-modal' do
          fill_in 'project_milestone_name', with: 'New Milestone 1'
          find('.btn-primary', visible: :all).click
        end
        click_button 'create-project-save-button'
      end
    end
    context 'added facilitator is not a valid user' do
      it 'shows error' do
        within '#add-staff-project-facilitators-modal' do
          fill_in 'project_facilitator_name', with: 'nonexistentuser@unknown.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          find('.btn-primary', visible: :all).click
        end
        click_button 'create-project-save-button'
        expect(page).to have_text('"nonexistentuser@unknown.ac.uk" is not a valid user email')
      end
    end
  end

  # VALID SUBMISSIONS

  describe 'User can succesfully create a new project with valid parameters' do
    before(:each) do
      login_as staff_user
      visit '/projects/new'
    end
    after(:each) do
      expect(page.current_path).to eq('/')
      latest_project_id = CourseProject.maximum(:id)
      created_project = CourseProject.find(latest_project_id)
      # remove the created project
      created_project.destroy
    end

    context 'by filling in module, name, team size, deadline' do
      it 'creates the project' do
        fill_in 'project_name', with: 'New Project'
        uncheck('project_choices_enable')
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        # Ensure groups are created
        expect(created_project.groups.size).to be > 1
        expect(created_project.groups.all? do |group|
                 group.students.size >= created_project.team_size
               end).to be_truthy
      end
    end
    context 'by filling in module, name, team size, deadline' do
      it 'creates the project' do
        fill_in 'project_name', with: 'New Project'
        uncheck('project_choices_enable')
        fill_in 'team_size', with: 6
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        # Ensure groups are created
        expect(created_project.groups.size).to be > 1
        expect(created_project.groups.all? do |group|
                 group.students.size >= created_project.team_size
               end).to be_truthy
      end
    end
    context 'by filling in module, name, project choices, team size, deadline, project preference form deadline' do
      it 'creates the project' do
        # doing actions that POST to an AJAX need to be done first as they cause a page re-render without JS
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 1'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 2'
          find('.btn-primary', visible: :all).click
        end
        fill_in 'project_name', with: 'New Project'
        # select('Team average preference', from: 'project_allocation_method')
        fill_in 'team_size', with: 6
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Project Preference Form Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        expect(created_project.subprojects.size).to be 2
        # Ensure groups are created
        expect(created_project.groups.size).to be > 1
        expect(created_project.groups.all? do |group|
                 group.students.size >= created_project.team_size
               end).to be_truthy
      end
    end
    context 'by filling in module, name, project choices, team size, deadline, preferred/avoided teammates, project preference form deadline, teammates preference form deadline' do
      it 'creates the project' do
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 1'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 2'
          find('.btn-primary', visible: :all).click
        end
        fill_in 'project_name', with: 'New Project'
        # select('Team average preference', from: 'project_allocation_method')
        fill_in 'team_size', with: 6
        select('Preference form based', from: 'team_allocation_method')
        fill_in 'preferred_teammates', with: 1
        fill_in 'avoided_teammates', with: 1
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Project Preference Form Deadline_date', with: '28/06/2099T00:00'
        fill_in 'milestone_Teammate Preference Form Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        expect(created_project.subprojects.size).to be 2
        # Groups shouldnt be created straight away when team allocation is preference form based
        expect(created_project.groups.size).to be 0
      end
    end
    context 'and define additional milestones' do
      it 'creates the project with associated milestones' do
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 1'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 2'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-milestone-modal' do
          fill_in 'project_milestone_name', with: 'New Milestone 1'
          find('.btn-primary', visible: :all).click
          fill_in 'project_milestone_name', with: 'New Milestone 2'
          find('.btn-primary', visible: :all).click
        end
        fill_in 'milestone_New Milestone 1_date', with: '28/06/2099T00:00'
        fill_in 'milestone_New Milestone 2_date', with: '28/06/2099T00:00'

        fill_in 'project_name', with: 'New Project'
        uncheck('project_choices_enable')
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'

        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        expect(created_project.milestones.size).to be 3
        # Ensure groups are created
        expect(created_project.groups.size).to be > 1
        expect(created_project.groups.all? do |group|
                 group.students.size >= created_project.team_size
               end).to be_truthy
      end
    end
    context 'and associate students/staff as facilitators' do
      it 'creates the project with associated facilitators' do
        within '#add-staff-project-facilitators-modal' do
          fill_in 'project_facilitator_name', with: 'awillis4@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          fill_in 'project_facilitator_name', with: 'jbala1@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          find('.btn-primary', visible: :all).click
        end

        fill_in 'project_name', with: 'New Project'
        uncheck('project_choices_enable')
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        expect(created_project.assigned_facilitators.size).to be 2
        # Ensure groups are created
        expect(created_project.groups.size).to be > 1
        expect(created_project.groups.all? do |group|
                 group.students.size >= created_project.team_size
               end).to be_truthy
      end
    end
    context 'and define additional milestones, and associated facilitators' do
      it 'creates the project with associated milestones and facilitators' do
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 1'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-choice-modal' do
          fill_in 'project_choice_name', with: 'Project Choice 2'
          find('.btn-primary', visible: :all).click
        end
        within '#add-project-milestone-modal' do
          fill_in 'project_milestone_name', with: 'New Milestone 1'
          find('.btn-primary', visible: :all).click
          fill_in 'project_milestone_name', with: 'New Milestone 2'
          find('.btn-primary', visible: :all).click
        end
        within '#add-staff-project-facilitators-modal' do
          fill_in 'project_facilitator_name', with: 'awillis4@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          fill_in 'project_facilitator_name', with: 'jbala1@sheffield.ac.uk'
          within '.modal-body' do
            find('.btn-outline-secondary', visible: :all).click
          end
          find('.btn-primary', visible: :all).click
        end
        fill_in 'milestone_New Milestone 1_date', with: '28/06/2099T00:00'
        fill_in 'milestone_New Milestone 2_date', with: '28/06/2099T00:00'

        fill_in 'project_name', with: 'New Project'
        uncheck('project_choices_enable')
        fill_in 'milestone_Project Deadline_date', with: '28/06/2099T00:00'
        click_button 'create-project-save-button'
        latest_project_id = CourseProject.maximum(:id)
        created_project = CourseProject.find(latest_project_id)
        expect(created_project.milestones.size).to be 3
        expect(created_project.assigned_facilitators.size).to be 2
      end
    end
  end
end
