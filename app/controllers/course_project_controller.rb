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
    # load_and_authorize_resource

    skip_before_action :verify_authenticity_token, only: [:new_project_remove_project_choice,
        :new_project_clear_facilitator_selection,
        :new_project_toggle_project_choices,
        :new_project_remove_project_milestone,
        :new_project_remove_from_facilitator_selection,
        :new_project_remove_facilitator,
        :create]

    def index
        if current_user.is_staff?
            render 'index_module_leader'
        else
            #FILTER FOR PROJECTS THAT ARE AVAILABLE FOR STUDENT ...
            @projects = CourseProject.all
            render 'index_student'
        end
    end

    def new
        staff_id = Staff.where(email: current_user.email).first
        modules_hash = CourseModule.where(staff_id: staff_id).order(:code).pluck(:code, :name).to_h
        puts modules_hash
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
    def new_project_add_project_choice
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

    def new_project_remove_project_choice
        @project_choice_name = params[:item_text].strip
        session[:new_project_data][:project_choices].delete(@project_choice_name)
        if request.xhr?
        else
            render :new
        end
    end

    def new_project_add_project_milestone
        @project_milestone_name = params[:project_milestone_name]
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

    def new_project_remove_project_milestone
        @project_milestone_name = params[:item_text].strip
        filtered_milestones = session[:new_project_data][:project_milestones].reject do |milestone|
            milestone[:Name] == @project_milestone_name
        end
        session[:new_project_data][:project_milestones] = filtered_milestones
        if request.xhr?
        else
            render :new
        end
    end

    def new_project_clear_facilitator_selection
        session[:new_project_data][:facilitator_selection] = []
    end

    def new_project_add_to_facilitator_selection
        @facilitator_email = params[:project_facilitator_name]
        if @facilitator_email.present?
            session[:new_project_data][:facilitator_selection] << @facilitator_email
        end
    end

    def new_project_remove_from_facilitator_selection
        @facilitator_email = params[:item_text].strip
        session[:new_project_data][:facilitator_selection].delete(@facilitator_email)
    end

    def new_project_add_facilitator_selection
        @facilitators_added = []
        session[:new_project_data][:facilitator_selection].each do |facilitator|
            unless session[:new_project_data][:project_facilitators].include?(facilitator)
              session[:new_project_data][:project_facilitators] << facilitator
              @facilitators_added << facilitator
            end
        end
    end

    def new_project_remove_facilitator
        @facilitator_email = params[:item_text]
        session[:new_project_data][:project_facilitators].delete(@facilitator_email)
        puts "REMOVING: ", @facilitator_email
        puts session[:new_project_data][:project_facilitators]
    end

    def new_project_search_facilitators_student
        query = params[:query]
        @results = Student.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def new_project_search_facilitators_staff
        query = params[:query]
        @results = Staff.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def new_project_get_milestone_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        respond_to do |format|
            format.json { render json: milestone }
        end
    end

    def new_project_set_milestone_email_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone[:Email][:Content] = params[:milestone_email_content]
        milestone[:Email][:Advance] = params[:milestone_email_advance]
    end

    def new_project_set_milestone_comment
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        puts milestone_name
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
        errors[:main] = {}
        unless CourseModule.exists?(code: project_data[:selected_module])
            errors[:main][:module_doesnt_exist] = "The selected module does not exist"
        end
        unless project_data[:project_name].present?
            errors[:main][:project_name_empty] = "Project name cannot be empty"
        end
        if !errors[:main].present? && CourseProject.exists?(name: project_data[:project_name], course_module_id: CourseModule.where(code: project_data[:selected_module]).first.id)
            errors[:main][:project_name_empty] = "There exists a project on this module with the same name"
        end

        # Project Choices
        project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
        project_data[:selected_project_allocation_mode] = params[:project_allocation_method]
        errors[:project_choices] = {}
        unless CourseProject.project_allocations.key?(project_data[:selected_project_allocation_mode])
            errors[:project_choices][:project_allocation_mode_invalid] = "Invalid project allocation mode selected"
        end
        if !project_data[:project_choices].present? && project_data[:project_choices_enabled]
            errors[:project_choices][:no_project_choices] = "Add some project choices, or disable this section"
        end

        # Team Config
        project_data[:team_size] = params[:team_size]
        project_data[:selected_team_allocation_mode] = params[:team_allocation_method]
        errors[:team_config] = {}
        unless CourseProject.team_allocations.key?(project_data[:selected_team_allocation_mode])
            errors[:team_config][:selected_team_allocation_mode] = "Invalid team allocation mode selected"
        end

        # Team Preference Form
        project_data[:preferred_teammates] = params[:preferred_teammates]
        project_data[:avoided_teammates] = params[:avoided_teammates]
        errors[:team_pref] = {}
        unless project_data[:preferred_teammates].present?
            errors[:team_pref][:invalid_pref_teammates] = "Invalid preferred teammates entry"
        end
        unless project_data[:avoided_teammates].present?
            errors[:team_pref][:invalid_pref_teammates] = "Invalid avoided teammates entry"
        end

        # Timings
        project_data[:project_deadline] = params["milestone_Project Deadline_date"]
        project_data[:teammate_preference_form_deadline] = params["milestone_Teammate Preference Form Deadline_date"]
        project_data[:project_preference_form_deadline] = params["milestone_Project Preference Form Deadline_date"]

        errors[:timings] = {}

        unless project_data[:project_deadline].present?
            errors[:timings][:project_deadline_not_set] = "Please set project deadline"
        end
        if project_data[:selected_team_allocation_mode] != "random_team_allocation" && !project_data[:teammate_preference_form_deadline].present?
            errors[:timings][:team_pref_deadline_not_set] = "Please set team preference form deadline"
        end
        if (project_data[:project_choices_enabled] && project_data[:selected_project_allocation_mode] != "random_project_allocation") && !project_data[:project_preference_form_deadline].present?
            errors[:timings][:project_pref_deadline_not_set] = "Please set project preference form deadline"
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
                        errors[:timings][:milestone_date_not_set] = "Please make sure all milestones have a date"
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
                        errors[:timings][:invalid_milestone_type] = "Please make sure all milestone types are valid"
                    end
                end
            end
        end

        facilitators_not_found = project_data[:project_facilitators].reject do |email|
            Student.exists?(email: email) || Staff.exists?(email: email)
        end
        errors[:facilitators_not_found] = facilitators_not_found

        no_errors = errors.all? { |_, v| v.empty? }
        if no_errors
            # Creating Project Model
            new_project = CourseProject.new(
                course_module_id: CourseModule.where(code: project_data[:selected_module]).first.id,
                name: project_data[:project_name],
                project_choices_json: project_data[:project_choices_enabled] ? project_data[:project_choices].to_json : "[]",
                project_allocation: project_data[:selected_project_allocation_mode].to_sym,
                team_size: project_data[:team_size],
                team_allocation: project_data[:selected_team_allocation_mode].to_sym,
                preferred_teammates:  project_data[:preferred_teammates],
                avoided_teammates: project_data[:avoided_teammates],
                status: :draft
            )
            if new_project.save!
                puts new_project.id
            end

            # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
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

            # Creating associated milestones
            project_data[:project_milestones].each do |milestone_data|
                puts "Preparing milestone: ", milestone_data
                puts "course id: ", new_project.id

                # dd/mm/yyyy to yyyy-mm-dd
                date_string = milestone_data[:Date]
                puts date_string
                next if !date_string.present?   #dont push the milestone if its not got a set date
                parsed_date = Date.strptime(date_string, "%d/%m/%Y").strftime("%Y-%m-%d")
                puts parsed_date

                json_data = {
                    "Name" => milestone_data[:Name],
                    "isDeadline" => milestone_data[:isDeadline],
                    "Email" => milestone_data[:Email],
                    "Comment" => milestone_data[:Comment]
                }
                puts json_data

                milestone = Milestone.new(
                    json_data: json_data,
                    deadline: parsed_date,
                    milestone_type: milestone_data[:Type],
                    course_project_id: new_project.id
                )

                if milestone.save!
                    puts "milestone: ", milestone, "saved succesfully"
                else
                    puts "milestone: ", milestone, "was not saved"
                end
            end

            #Creating assigned facilitators
            project_data[:project_facilitators].each do |user_email|

                facilitator = AssignedFacilitator.new(course_project_id: new_project.id);

                if Staff.exists?(email: user_email)
                    facilitator.staff_id = Staff.where(email: user_email).first.id
                elsif Student.exists?(email: user_email)
                    facilitator.student_id = Student.where(email: user_email).first.id
                end

                facilitator.save!
            end
        end

        # May need further changes here to accoutn for if any of the database commits (.save!) dont go through
        if no_errors
            flash[:notice] = "Project has been created successfully"
            redirect_to action: :index
        else
            render :new
        end
    end

    def show_student
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

        #Get ordered milestones and project deadline
        @milestones = []
        @current_project.milestones.order('deadline').each do |milestone|
            if milestone.json_data['Name'] == 'Project Deadline'
                @deadline = milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
            else
                @milestones << milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
            end
        end
    end

    def teams

    end
end
