require 'rails_helper'

RSpec.feature "Project Creation", type: :feature do
    let!(:user){FactoryBot.create(:standard_student_user)}
    let!(:student) { FactoryBot.create(:standard_student) } # without this line, cant log in?
    let!(:staff) { Staff.find_or_create_by(email: user.email) }

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
            project_allocation: :single_preference_project_allocation,
            team_allocation: :random_team_allocation,
            team_size: 8
        })

        # Capybara.current_driver = :selenium
    end
    after(:all) do
        # Capybara.current_driver = Capybara.default_driver
    end

    # Fill in ALL project creation fields, only missing name so it doesnt succesfully submit
    def fill_in_all_except_name

    end

    # UX

    describe "User can toggle Project Choices visibility" do
        context "when clicking the toggle button" do
            it "hides the Project Choices panel if it is currently visible", js: true do
                # login_as user
                # visit "/projects/new"
                # find('#project-choices-enable').uncheck
                # expect(page).to have_css('#project-choices.display-none')
            end
        end
    end

    describe "User gets shown deadline for the teammate preference form, and the preference form settings" do
        context "when they set the team allocation mode to preference form" do
            it "Shows teammate preference form deadline" do
            end
            it "Shows teammate preference form settings" do
            end
        end
    end

    describe "Creation form gets filled with correct fields" do
        before(:each) do
            login_as user
            visit "/projects/new"
        end
        context "when the page is first loaded" do
            it "fills in module options with modules that user is a module lead for" do
                select_element = find("select[name='module_selection']")
                options = select_element.all("option")
                save_and_open_page
                options.each do |option|
                    course_module_code = option.value
                    course_module = CourseModule.find_by(code: course_module_code)
                    expect(course_module.staff_id).to eq(staff.id)
                end
            end
            it "fills in correct project allocation methods into selection" do
                select_element = find("select[name='project_allocation_method']")
                options = select_element.all("option")
                project_allocation_methods = CourseProject.project_allocations.keys
                options.each do |option|
                    expect(project_allocation_methods).to include(option.value)
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
        end
        context "when the page is reloaded on a failed submission" do
            before(:each) do
                fill_in_all_except_name
            end
            it "fills in module options with modules that user is a module lead for" do
            end
            it "fills in correct project allocation methods into selection" do
            end
            it "fills in correct team allocation methods into selection" do
            end
            it "persists the project name" do
            end
            it "persists the previous selected module" do
            end
            it "persists all added project choices" do
            end
            it "persists the previous selected project allocation method" do
            end
            it "persists the previous seleted team allocation method" do
            end 
            it "persists set team size" do
            end
            it "persists preferred and avoided teammates" do 
            end
            it "persists all deadline data" do
            end
            it "persists all added milestones and their data" do
            end
            it "persists all added facilitators" do
            end
        end
    end


    # INVALID SUBMISSIONS

    # describe "User tries to create a new project with invalid parameters" do

    #     before(:each) do
    #         login_as user
    #         visit "/projects/new"
    #     end
    #     after(:each) do
    #         expect(page.current_path).to eq("/projects/new")
    #     end
    #     context "Project Name is left empty" do
    #         it "shows error" do
    #             click_button 'create-project-save-button'
    #             expect(page).to have_text("Project name cannot be empty")
    #         end
    #     end
    #     context "Project Name is taken by another on the module" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Module is invalid" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Project choices enabled but none given" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Project Allocation method is invalid" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Team size is invalid" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Teammate Preference form has both fields as 0" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Team allocation mode is invalid" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Project deadline not set" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Teammate preference form deadline not set" do
    #         it "shows error" do
    #         end
    #     end
    #     context "Project preference form deadline not set" do
    #         it "shows error" do
    #         end
    #     end
    #     context "milestone dates left unset" do
    #         it "shows error" do
    #         end
    #     end
    #     context "added facilitator is not a valid user" do
    #         it "shows error" do
    #         end
    #     end

    # end

    # # VALID SUBMISSIONS

    # describe "User can succesfully create a new project with valid parameters" do

    #     before(:each) do
    #         login_as user
    #         visit "/projects/new"
    #     end
    #     after(:each) do
    #         # remove the created project
    #         expect(page.current_path).to eq("/projects")
    #     end

    #     context "by filling in module, name, team size, deadline" do
    #         it "creates the project" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "by filling in module, name, team size, deadline" do
    #         it "creates the project" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "by filling in module, name, project choices, team size, deadline, project preference form deadline" do
    #         it "creates the project" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "by filling in module, name, project choices, team size, deadline, preferred/avoided teammates, project preference form deadline, teammates preference form deadline" do
    #         it "creates the project" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "by filling in all fields" do
    #         it "creates the project" do
    #         end 
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "and define additional milestones" do
    #         it "creates the project with associated milestones" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "and associate students/staff as facilitators" do
    #         it "creates the project with associated facilitators" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    #     context "and define additional milestones, and associated facilitators" do
    #         it "creates the project with associated milestones and facilitators" do
    #         end
    #         it "creates groups of specified team size associated to the project" do
    #         end
    #     end
    # end

end