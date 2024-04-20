require 'json'

# INTAKE/OUTTAKE: How its stored in the model
# Session Fromat: How its stored in the controller session hash

# Project Choices INTAKE/OUTTAKE:
# JSON: { "1": "Project Choice A"
#         "2": "Project Choice B"}
# Project choices Session Format:
# ["Project Choice A", "Project Choice B"]

# Project Milestones INTAKE/OUTTAKE:
# New Milestone Model
# Project Milestones Session Format:
# [ {"Name": "Technical Review", "Date": "dd/mm/yyyy"},
#   {"Name": "Peer Review", "Date: "dd/mm/yyyy"}]

class CourseProjectController < ApplicationController

    load_and_authorize_resource

    skip_before_action :verify_authenticity_token, only: [
        :remove_project_choice,
        :clear_facilitator_selection,
        :toggle_project_choices,
        :remove_project_milestone,
        :remove_from_facilitator_selection,
        :remove_facilitator,
        :create
    ]

    def index
        if current_user.is_staff?
            @projects = current_user.staff.course_projects
            render 'index_module_leader'
        else
            @projects = current_user.student.course_projects
            render 'index_student'
        end
    end

    def new
        staff_id = Staff.where(email: current_user.email).first
        modules_hash = CourseModule.all.pluck(:code, :name).to_h # where(staff_id: staff_id).order(:code).pluck(:code, :name)
        project_allocation_modes_hash = CourseProject.project_allocations
        team_allocation_modes_hash = CourseProject.team_allocations
        milestone_types_hash = Milestone.milestone_types

        session[:new_project_data] = {
            errors: {},
            modules_hash: modules_hash,
            project_allocation_modes_hash: project_allocation_modes_hash,
            team_allocation_modes_hash: team_allocation_modes_hash,
            milestone_types_hash: milestone_types_hash,

            selected_module: "",
            project_name: "",
            selected_project_allocation_mode: "",
            project_choices: [],
            team_size: 4,
            selected_team_allocation_mode: "",
            preferred_teammates: 2,
            avoided_teammates: 2,
            project_milestones: [{"Name": "Project Deadline", "Date": "", "Type": "team", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Project Preference Form Deadline", "Date": "", "Type": "team", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""}],
            project_facilitators: [],

            facilitator_selection: [],
            project_choices_enabled: true
        }
    end

    # POST
    def add_project_choice
        @project_choice_name = params[:project_choice_name]
        session[:new_project_data][:project_choices] << @project_choice_name

        # If done via AJAX (JavaScript enabled), dynamically add
        if request.xhr?
            respond_to do |format|
                format.js
            end

        # Otherwise re-render :new
        else
            render :new
        end
    end

    def remove_project_choice
        @project_choice_name = params[:item_text].strip
        session[:new_project_data][:project_choices].delete(@project_choice_name)
        if request.xhr?
        else
            render :new
        end
    end

    def add_project_milestone
        @project_milestone_name = params[:project_milestone_name]
        @project_milestone_name.gsub('_', ' ')
        project_milestone_unique = false
        unless session[:new_project_data][:project_milestones].any? { |milestone| milestone[:Name] == @project_milestone_name }
            session[:new_project_data][:project_milestones] << {"Name": @project_milestone_name, "Date": "", "Type": "", "isDeadline": false, "Email": {"Content": "", "Advance": ""}, "Comment": ""}
            project_milestone_unique = true
        end
        if request.xhr?
            respond_to do |format|
                if project_milestone_unique
                    format.js
                end
            end
        else
            render :new
        end
    end

    def remove_project_milestone
        @project_milestone_name = params[:item_text].strip.match(/^milestone_([^_]+)/)[1]
        filtered_milestones = session[:new_project_data][:project_milestones].reject do |milestone|
            milestone[:Name] == @project_milestone_name
        end
        session[:new_project_data][:project_milestones] = filtered_milestones

        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def clear_facilitator_selection
        session[:new_project_data][:facilitator_selection] = []
    end

    def add_to_facilitator_selection
        @facilitator_email = params[:project_facilitator_name]
        if @facilitator_email.present?
            session[:new_project_data][:facilitator_selection] << @facilitator_email
        end
        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def remove_from_facilitator_selection
        @facilitator_email = params[:item_text].strip
        session[:new_project_data][:facilitator_selection].delete(@facilitator_email)
    end

    def add_facilitator_selection
        @facilitators_added = []
        session[:new_project_data][:facilitator_selection].each do |facilitator|
            unless session[:new_project_data][:project_facilitators].include?(facilitator)
              session[:new_project_data][:project_facilitators] << facilitator
              @facilitators_added << facilitator
            end
        end
        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def remove_facilitator
        @facilitator_email = params[:item_text]
        session[:new_project_data][:project_facilitators].delete(@facilitator_email)
    end

    def search_facilitators_student
        query = params[:query]
        @results = Student.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def search_facilitators_staff
        query = params[:query]
        @results = Staff.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def get_milestone_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        respond_to do |format|
            format.json { render json: milestone }
        end
    end

    def set_milestone_email_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone[:Email][:Content] = params[:milestone_email_content]
        milestone[:Email][:Advance] = params[:milestone_email_advance]
    end

    def set_milestone_comment
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone[:Comment] = params[:milestone_comment]
    end

    def create

        session[:new_project_data][:errors] = {}
        errors = session[:new_project_data][:errors]

        project_data = session[:new_project_data]

        # Main Data
        project_data[:project_name] = params[:project_name]
        project_data[:selected_module] = params[:module_selection]
        errors[:main] = []
        unless CourseModule.exists?(code: project_data[:selected_module])
            errors[:main] << "The selected module does not exist"
        end

        # Project Choices
        project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
        project_data[:selected_project_allocation_mode] = params[:project_allocation_method]
        errors[:project_choices] = []

        if !project_data[:project_choices].present? && project_data[:project_choices_enabled]
            errors[:project_choices] << "Add some project choices, or disable this section"
        end

        # Team Config
        project_data[:team_size] = params[:team_size]
        project_data[:selected_team_allocation_mode] = params[:team_allocation_method]
        errors[:team_config] = []

        # Team Preference Form
        project_data[:preferred_teammates] = params[:preferred_teammates]
        project_data[:avoided_teammates] = params[:avoided_teammates]
        errors[:team_pref] = []

        # Timings
        project_data[:project_deadline] = params["milestone_Project Deadline_date"]
        project_data[:teammate_preference_form_deadline] = params["milestone_Teammate Preference Form Deadline_date"]
        project_data[:project_preference_form_deadline] = params["milestone_Project Preference Form Deadline_date"]

        errors[:timings] = []

        unless project_data[:project_deadline].present?
            errors[:timings] << "Please set project deadline"
        end
        if project_data[:selected_team_allocation_mode] != "random_team_allocation" && !project_data[:teammate_preference_form_deadline].present?
            errors[:timings] << "Please set team preference form deadline"
        end
        if (project_data[:project_choices_enabled] && project_data[:selected_project_allocation_mode] != "random_project_allocation") && !project_data[:project_preference_form_deadline].present?
            errors[:timings] << "Please set project preference form deadline"
        end

        params.each do |key, value|
            # Check if the key starts with "milestone_"
            if key.match?(/^milestone_[^_]+_date$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Date" value
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    milestone[:Date] = value
                    unless (defined?(value) && value.present?) || milestone[:isDeadline]
                        err = "Please make sure all milestones have a date"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end

            if key.match?(/^milestone_[^_]+_type$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Type" value
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    next if milestone[:isDeadline]
                    milestone[:Type] = value
                    unless defined?(value) && value.present? && Milestone.milestone_types.key?(value)
                        err = "Please make sure all milestone types are valid"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end
        end

        facilitators_not_found = project_data[:project_facilitators].reject do |email|
            Student.exists?(email: email) || Staff.exists?(email: email)
        end
        errors[:facilitators_not_found] = facilitators_not_found

        no_errors = errors.all? { |_, v| v.empty? }
        # Creating Project Model
        new_project = CourseProject.new(
            course_module: CourseModule.find_by(code: project_data[:selected_module]),
            name: project_data[:project_name],
            project_choices_json: project_data[:project_choices_enabled] ? project_data[:project_choices].to_json : "[]",
            project_allocation: project_data[:selected_project_allocation_mode].to_sym,
            team_size: project_data[:team_size],
            team_allocation: project_data[:selected_team_allocation_mode].to_sym,
            preferred_teammates:  project_data[:preferred_teammates],
            avoided_teammates: project_data[:avoided_teammates],
            status: :draft
        )

        if new_project.valid? && no_errors
            new_project.save
        else
            new_project.errors.messages.each do |section, section_errors|
                section_errors.each do |error|
                    (errors[section.to_sym] ||= []) << error
                end
            end
        end
        no_errors = errors.all? { |_, v| v.empty? }

        # Create sub projects models and associate them to this project
        if no_errors
            subprojects = []
            if project_data[:project_choices_enabled]
                project_data[:project_choices].each do |project_choice|
                    subproject = Subproject.new(
                        name: project_choice,
                        json_data: "{}",
                        course_project_id: new_project.id
                    )
                    subprojects << subproject
                end
            end
            subprojects.each do |subproject|
                if subproject.valid?
                    subproject.save
                else
                    new_project.destroy
                    subproject.errors.messages.each do |attribute, messages|
                        messages.each do |message|
                          unless errors[:timings].include?("Subproject error: #{attribute} : #{message}")
                            errors[:timings] << "Subproject error: #{attribute} : #{message}"
                          end
                        end
                    end
                end
            end
        end
        no_errors = errors.all? { |_, v| v.empty? }

        # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
        if no_errors
            if project_data[:selected_team_allocation_mode] == "random_team_allocation"
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == "Teammate Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
            if !project_data[:project_choices_enabled] || project_data[:selected_project_allocation_mode] == "random_project_allocation"
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == "Project Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
        end

        # Creating associated milestones
        if no_errors
            milestones = []
            project_data[:project_milestones].each do |milestone_data|

                # dd/mm/yyyy to yyyy-mm-dd
                date_string = milestone_data[:Date]
                # This did a funny where sometimes the format was recieved as m/d/y, hasnt happened again since what should have fixed it
                # puts date_string
                next if !date_string.present?   #dont push the milestone if its not got a set date
                parsed_date = Date.strptime(date_string, "%d/%m/%Y").strftime("%Y-%m-%d")
                # puts parsed_date

                json_data = {
                    "Name" => milestone_data[:Name],
                    "isDeadline" => milestone_data[:isDeadline],
                    "Email" => milestone_data[:Email],
                    "Comment" => milestone_data[:Comment]
                }

                milestone = Milestone.new(
                    json_data: json_data,
                    deadline: parsed_date,
                    milestone_type: milestone_data[:Type],
                    course_project_id: new_project.id
                )

                milestones << milestone
            end

            milestones.each do |milestone|
                if milestone.valid?
                    milestone.save
                else
                    new_project.destroy
                    milestone.errors.messages.each do |attribute, messages|
                        messages.each do |message|
                          unless errors[:main].include?("Milestone error: #{attribute} : #{message}")
                            errors[:main] << "Milestone error: #{attribute} : #{message}"
                          end
                        end
                    end
                end
            end
        end
        no_errors = errors.all? { |_, v| v.empty? }

        #Creating assigned facilitators
        if no_errors
            facilitators = []
            project_data[:project_facilitators].each do |user_email|

                facilitator = AssignedFacilitator.new(course_project_id: new_project.id);

                if Staff.exists?(email: user_email)
                    facilitator.staff_id = Staff.where(email: user_email).first.id
                elsif Student.exists?(email: user_email)
                    facilitator.student_id = Student.where(email: user_email).first.id
                end

                facilitators << facilitator
            end
            facilitators.each do |facilitator|
                if facilitator.valid?
                    facilitator.save
                else
                    new_project.destroy
                    facilitator.errors.messages.each do |attribute, messages|
                        messages.each do |message|
                          unless errors[:main].include?("Facilitator error: #{attribute} : #{message}")
                            errors[:main] << "Facilitator error: #{attribute} : #{message}"
                          end
                        end
                    end
                end
            end
        end
        no_errors = errors.all? { |_, v| v.empty? }

        # Creating groups (currently just puts everyone in groups of X size, no randomness or preference)
        if no_errors
            module_students = CourseModule.find_by(code: project_data[:selected_module]).students
            team_size = project_data[:team_size].to_i
            groups = []
            current_group = nil
            team_count = 0

            module_students.each_slice(team_size) do |students_slice|

                # Create a new group for each slice of students
                current_group = Group.new
                team_count += 1
                current_group.name = "Team " + team_count.to_s
                current_group.course_project_id = new_project.id

                # Add students to the current group
                students_slice.each do |student|
                current_group.students << student
                end

                # Add the current group to the list of groups
                groups << current_group
            end

            # Save each group using save!
            groups.each do |group|
                if group.valid?
                    group.save
                else
                    new_project.destroy
                    group.errors.messages.each do |attribute, messages|
                        messages.each do |message|
                          unless errors[:main].include?("Group error: #{attribute} : #{message}")
                            errors[:main] << "Group error: #{attribute} : #{message}"
                          end
                        end
                    end
                end
            end
        end

        no_errors = errors.all? { |_, v| v.empty? }
        if no_errors
            # flash[:notice] = "Project has been created successfully"
            redirect_to action: :index
        else
            # render :new
            render :new
        end
    end

    def show
        if current_user.is_staff?
            # staff version of viewing one project
        else
            @current_project = CourseProject.find(params[:id])
            linked_module = @current_project.course_module
            @proj_name = linked_module.code+' '+linked_module.name+' - '+@current_project.name
            @lead = linked_module.staff.email

            #TODO - Change database interactions to only get records
            #       relevant to the GROUP the student is part of - only one facilitator?

            #Get staff + facilitator information
            @facilitators = []
            AssignedFacilitator.where(course_project_id: @current_project.id).each do |facilitator|
                if facilitator.staff_id == nil
                    @facilitators << Student.find(facilitator.student_id).email
                else
                    @facilitators << Staff.find(facilitator.staff_id).email
                end
            end

            #Get ordered milestones and deadlines
            first_response = false
            @milestones = []
            @current_project.milestones.order('deadline').each do |milestone|
                if milestone.json_data['Name'] == 'Project Deadline'
                    @deadline = milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                elsif milestone.json_data['Name'] == 'Teammate Preference Form Deadline'
                    @pref_form = milestone
                    @milestones << milestone.json_data['Name']+': '+milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']

                    #Should the preference form be shown
                    if MilestoneResponse.where(milestone_id: @pref_form.id, student_id: current_user.student.id).empty?
                        first_response = true
                    end
                else
                    @milestones << milestone.json_data['Name']+': '+milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                end
            end

            #Preference Form
            @yes_mates = @current_project.preferred_teammates.to_i
            @no_mates = @current_project.avoided_teammates.to_i

            if (@current_project.team_allocation == 'preference_form_based') && (@current_project.status == 'student_preference') && first_response
                @show_pref_form = true
            else
                @show_pref_form = false
            end

            #Project Choices

            #Render view
            render 'show_student'

        end
    end

    def teams

    end
end
