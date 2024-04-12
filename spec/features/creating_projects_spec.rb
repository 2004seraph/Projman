require 'rails_helper'

RSpec.feature "Project Creation", type: :feature do
    let!(:user){FactoryBot.create(:standard_student_user)}
    let!(:student){FactoryBot.create(:standard_student)}

    before(:all) do
        DatabaseHelper.create_staff("awillis4@sheffield.ac.uk")
        DatabaseHelper.provision_module_class(
            "COM9999",
            "Test Module 1",
            Staff.find_by(email: "awillis4@sheffield.ac.uk")
        )
        DatabaseHelper.provision_module_class(
            "COM8888",
            "Test Module 2",
            Staff.find_by(email: "awillis4@sheffield.ac.uk")
        )
        CourseProject.find_or_create_by({
            course_module: CourseModule.find_by(code: "COM9999"),
            name: "Test Project 1",
            project_allocation: :individual_preference_project_allocation,
            team_allocation: :random_team_allocation,
            team_size: 8
        })
    end

    describe "User can toggle Project Choices visibility" do
        context "when clicking the toggle button" do
            it "hides the Project Choices panel if it is currently visible" do
            end
        end
    end

    describe "Project Choices visibility persists after failed submission" do
        context "when it was previousely enabled" do
            it "stays enabled" do
            end
        end
        context "when it was previously disabled" do
            it "stays disabled" do
            end
        end
    end

    describe "Creation form gets filled with correct fields" do

    end


    describe "User tries to create a new project with invalid parameters" do
        context "Project Name is left empty" do
            it "shows error" do
                login_as user
                visit "/projects/new"
                click_button 'create-project-save-button'
                save_and_open_page
                expect(page).to have_text("Project name cannot be empty")
            end
        end
    end

end