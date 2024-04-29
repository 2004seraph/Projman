require 'rails_helper'

RSpec.feature "Project Creation", type: :feature do
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
    # DatabaseHelper.provision_module_class(
    #     "COM8888",
    #     "Test Module 1",
    #     Staff.find_by(email: "awillis4@sheffield.ac.uk")
    # )
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
    context "When I clicking the report button" do
      it "shows the report issue modal" do
        Capybara.ignore_hidden_elements = false

        login_as user
        visit "/projects"
        find(".project-button").click
        expect(page).to have_
      end
    end
  end