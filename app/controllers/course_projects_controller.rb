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

class CourseProjectsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:new_project_remove_project_choice,
        :new_project_clear_facilitator_selection,
        :new_project_toggle_project_choices,
        :new_project_remove_project_milestone,
        :new_project_remove_from_facilitator_selection,
        :new_project_remove_facilitator]

    def index
        @view_as_manager = true
        if @view_as_manager            
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def new
        modules_hash = CourseModule.order(:code).pluck(:code, :name).to_h
        project_allocation_modes_hash = CourseProject.project_allocations
        team_allocation_modes_hash = CourseProject.team_allocations
        milestone_types_hash = Milestone.types

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
            project_milestones: [{"Name": "Project Deadline", "Date": "", "Type": "team", "Deadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student", "Deadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Project Preference Form Deadline", "Date": "", "Type": "team", "Deadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""}],
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
            session[:new_project_data][:project_milestones] << {"Name": @project_milestone_name, "Date": "", "Type": "", "Deadline": false, "Email": {"Content": "", "Advance": ""}, "Comment": ""}
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
                    next if milestone[:Deadline]
                    milestone[:Date] = value
                    unless defined?(value) && value.present?
                        errors[:timings][:milestone_date_not_set] = "Please make sure all milestones have a date"
                    end
                end
            end

            if key.match?(/^milestone_[^_]+_type$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]
          
                # Find the corresponding milestone in the milestones hash and update its "Type" value
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    next if milestone[:Deadline]
                    milestone[:Type] = value
                    unless defined?(value) && value.present? && Milestone.types.key?(value)
                        errors[:timings][:invalid_milestone_type] = "Please make sure all milestone types are valid"
                    end
                end
            end
        end

        puts project_data[:project_milestones]


        facilitators_not_found = project_data[:project_facilitators].reject do |email|
            Student.exists?(email: email) || Staff.exists?(email: email)
        end
        errors[:facilitators_not_found] = facilitators_not_found

        render :new
    end
end
