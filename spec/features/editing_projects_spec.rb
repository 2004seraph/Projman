
require "rails_helper"

RSpec.feature "Project Creation", type: :feature do
  let!(:staff_user) { FactoryBot.create(:standard_staff_user) }

  before(:all) do
    DatabaseHelper.create_staff("awillis4@sheffield.ac.uk")
    DatabaseHelper.create_staff("jbala1@sheffield.ac.uk")
    DatabaseHelper.create_staff("sgttaseff1@sheffield.ac.uk")
    DatabaseHelper.provision_module_class(
      "COM9999",
      "Test Module 2",
      Staff.find_by(email: "awillis4@sheffield.ac.uk")
    )
    DatabaseHelper.provision_module_class(
      "COM8888",
      "Test Module 1",
      Staff.find_by(email: "awillis4@sheffield.ac.uk")
    )

    DatabaseHelper.create_course_project(options={
      module_code:           "COM8888",
      name:                  "New Project",
      status:                "draft",
      project_choices:       ["Choice 1", "Choice 2"],
      team_size:             5,
      preferred_teammates:   1,
      avoided_teammates:     2,
      team_allocation_mode:  "random_team_allocation",
      teams_from_project_choice: false,

      project_deadline:      DateTime.now + 1.days,
      project_pref_deadline: DateTime.now + 23.hours,

      milestones:            [
        {
          "Name":     "Milestone 1",
          "Deadline": DateTime.now + 10.minutes,
          "Email":    { "Content": "This is an email", "Advance": 0 },
          "Comment":  "This is a comment",
          "Type":     "team"
        }
      ],

      facilitators:          ["jbala1@sheffield.ac.uk", "sgttaseff1@sheffield.ac.uk"]
    })

    # Capybara.current_driver = :selenium
  end

  describe "Edit form gets filled with correct fields" do
    before(:each) do
      login_as staff_user
      p = CourseProject.find_by(name: "New Project")
      visit "/projects/#{p.id}/edit"
    end

    context "when the page is first loaded" do
      it "fills in module options with modules that user is a module lead for" do
        select_element = find("select[name='module_selection']")
        options = select_element.all("option")
        options.each do |option|
          course_module_code = option.value
          course_module = CourseModule.find_by(code: course_module_code)
          expect(course_module.staff.email).to eq(staff_user.email)
        end
      end
      it "fills in correct team allocation methods into selection" do
        select_element = find("select[name='team_allocation_method']")
        options = select_element.all("option")
        team_allocation_methods = CourseProject.team_allocations.keys
        options.each do |option|
          expect(team_allocation_methods).to include(option.value)
        end
      end
      it "persists the project name" do
        expect(page).to have_field("project_name", with: "New Project")
      end
      it "persists the previous selected module" do
        expect(page).to have_select("module_selection", selected: "COM8888 Test Module 1")
      end
      it "persists all added project choices" do
        within "#project-choices" do
          expect(page).to have_content("Choice 1")
          expect(page).to have_content("Choice 2")
        end
      end
      it "persists the previous seleted team allocation method" do
        expect(page).to have_select("team_allocation_method", selected: "Random")
      end
      it "persists set team size" do
        expect(page).to have_field("team_size", with: "5")
      end
      it "persists preferred and avoided teammates" do
        expect(page).to have_field("preferred_teammates", with: "1")
        expect(page).to have_field("avoided_teammates", with: "2")
      end
      it "persists all deadline data" do
        expect(page).to have_field("milestone_Project Deadline_date", with: "#{(DateTime.now + 1.days).strftime('%Y-%m-%dT%H:%M')}")
        expect(page).to have_field("milestone_Project Preference Form Deadline_date", with: "#{(DateTime.now + 23.hours).strftime('%Y-%m-%dT%H:%M')}")
      end
      it "persists all added milestones" do
        within "#timings" do
          expect(page).to have_content("Milestone 1")
          expect(page).to have_field("milestone_Milestone 1_date", with: "#{(DateTime.now + 10.minutes).strftime('%Y-%m-%dT%H:%M')}")
        end
      end
      it "persists all added facilitators" do
        within "#project-facilitators" do
          expect(page).to have_content("sgttaseff1@sheffield.ac.uk")
          expect(page).to have_content("jbala1@sheffield.ac.uk")
        end
      end
    end
  end

  describe "Project succesfully updates" do
    before(:each) do
      login_as staff_user
      p = CourseProject.find_by(name: "New Project")
      visit "/projects/#{p.id}/edit"
    end

    context "after editing project name" do
      it "saves the new name" do
        fill_in "project_name", with: "New Project Renamed"
        click_button "create-project-save-button"
        latest_project_id = CourseProject.maximum(:id)
        updated_project = CourseProject.find(latest_project_id)
        expect(updated_project.name).to eq("New Project Renamed")
      end
    end
  end
end