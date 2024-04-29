require 'rails_helper'

RSpec.feature "Issue Creation", type: :feature do
  let!(:user){FactoryBot.create(:standard_student_user)}
  let!(:student) { FactoryBot.create(:standard_student) } # without this line, cant log in?
  
  let!(:user2){FactoryBot.create(:standard_student_user)}
  let!(:staff) { Staff.find_or_create_by(email: user2.email) }

  before(:all) do
    DatabaseHelper.create_staff("jhenson2@sheffield.ac.uk")
    DatabaseHelper.create_staff("jbala1@sheffield.ac.uk")
    DatabaseHelper.provision_module_class(
        "COM9999",
        "Test Module 1",
        Staff.find_by(email: "jhenson2@sheffield.ac.uk")
    )

    CourseProject.find_or_create_by({
        course_module: CourseModule.find_by(code: "COM9999"),
        name: "Test Project 1",
        project_allocation: :single_preference_project_allocation,
        team_allocation: :random_team_allocation,
        team_size: 8
    })

    # Capybara.current_driver = :selenium
  end
  after(:all) do
      # Capybara.current_driver = Capybara.default_driver
  end
  describe "Student can report an issue for a project", js: true do
    before(:each) do
      group = Group.find_or_create_by({
        name: "Team 1",
        assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "jbala1@sheffield.ac.uk"),
          course_project: CourseProject.find_by(name: "Test Project 1")),
        course_project: CourseProject.find_by(name: "Test Project 1")
      })
  
      student.enroll_module "COM9999"
      group.students << student
    end
    
    context "When I clicking the report button" do
      it "shows the report issue modal" do
        Capybara.ignore_hidden_elements = false

        
    

        login_as user
        visit "/projects"

        save_and_open_page
        find('#project-button-1').click
        expect(page).to have_selector('#reportIssueModal', visible: true)
      end
    end
  end
end