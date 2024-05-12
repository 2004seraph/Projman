# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require 'rails_helper'

describe 'Managing modules' do
  let!(:staff_user) { FactoryBot.create(:standard_staff_user, admin: true) }

  before { login_as staff_user }

  specify 'I can add a module' do
    visit '/modules'
    click_on 'Create New'

    fill_in 'course_module_code', with: 'COM1002'
    fill_in 'course_module_name', with: 'Introduction'
    fill_in 'new_module_lead_email', with: 'test@email'
    fill_in 'new_module_lead_email_confirmation', with: 'test@email'

    attach_file 'student_csv', Rails.root.join('spec/data/COM1002.csv').to_s

    click_on 'Save'

    expect(page).to have_content 'Module was successfully created.'
    expect(page).to have_content 'COM1002 Introduction'
  end

  context 'With one existing module' do
    before do
      DatabaseHelper.create_staff('awillis4@sheffield.ac.uk')
      DatabaseHelper.provision_module_class(
        'COM1002',
        'Introduction',
        Staff.find_by(email: 'awillis4@sheffield.ac.uk')
      )
    end

    before { visit '/modules' }

    specify 'I can view modules in a list' do
      expect(page).to have_content 'COM1002 Introduction'
    end
  end

  context 'When viewing a module' do
    before do
      DatabaseHelper.create_staff('awillis4@sheffield.ac.uk')
      DatabaseHelper.provision_module_class(
        'COM1002',
        'Introduction',
        Staff.find_by(email: 'awillis4@sheffield.ac.uk')
      )
    end

    before { visit '/modules' }

    before { click_on 'COM1002 Introduction' }

    specify 'I can view all module information' do
      expect(page).to have_content 'Introduction'
      expect(page).to have_content 'awillis4@sheffield.ac.uk'
      expect(page).to have_content CourseModule.find_by(code: 'COM1002').students.first.forename
    end

    specify 'I can edit the module name' do
      click_on 'change_name'

      fill_in 'new_module_name', with: 'Test'
      click_on 'name_confirm'

      expect(page).to have_content 'Module Name updated successfully.'
    end

    specify 'I can edit the module leader' do
      click_on 'change_lead'

      fill_in 'new_module_lead_email', with: 'test@email'
      fill_in 'new_module_lead_email_confirmation', with: 'test@email'
      click_on 'lead_confirm'

      expect(page).to have_content 'Module Leader updated successfully.'
    end

    specify 'I can edit the module name' do

      # save_and_open_page

      click_on 'change_students'

      attach_file 'new_module_student_list', Rails.root.join('spec/data/COM1002.csv').to_s
      click_on 'list_confirm'

      expect(page).to have_content 'Student List updated successfully.'
    end
  end
end
