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

        Capybara.current_driver = :selenium
    end
    after(:all) do
        # Capybara.current_driver = Capybara.default_driver
    end

    describe "User can toggle Project Choices visibility" do
        context "when clicking the toggle button" do
            it "hides the Project Choices panel if it is currently visible" do
                # login_as user
                # visit "/projects/new"
                # wait_for_javascript
                # find('#project-choices-enable').uncheck
                # sleep(5)
                # expect(page).to have_css('#project-choices.display-none')
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
        it "fills in module options with modules that user is a module lead for" do
        end
        it "fills in correct project allocation methods into selection" do
        end
        it "fills in correct team allocation methods into selection" do
        end
    end


    describe "User tries to create a new project with invalid parameters" do
        after(:each) do
            expect(page.current_path).to eq("/projects/new")
        end
        context "Project Name is left empty" do
            it "shows error" do
                login_as user
                visit "/projects/new"
                click_button 'create-project-save-button'
                expect(page).to have_text("Project name cannot be empty")
            end
        end
        context "Project Name is taken by another on the module" do
            it "shows error" do
            end
        end
    end

end