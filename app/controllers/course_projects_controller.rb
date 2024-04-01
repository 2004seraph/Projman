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
        :new_project_remove_project_milestone]

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

        session[:new_project_data] = {
            modules_hash: modules_hash,
            project_allocation_modes_hash: project_allocation_modes_hash,
            team_allocation_modes_hash: team_allocation_modes_hash,
            project_choices: ["Example Choice 1"],
            project_milestones: [],
            facilitator_selection: [],
            project_facilitators: [],
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
            session[:new_project_data][:project_milestones] << {"Name": @project_milestone_name, "Date": ""}
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
        session[:new_project_data][:facilitator_selection] << @facilitator_email
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
    end

    def create

        puts "PRESSED SAVE..."
        puts "SELECTED MODULE: " + params[:module_selection]
        if params[:project_name].present?
            puts "PROJECT NAME: " + params[:project_name]
        else
            puts "PROJECT NAME is not provided"
        end

        puts "---------------------------"

        if params.key?(:project_choices_enable)
            puts "PROJECTE CHOICES ENABLED: TRUE"
        else
            puts "PROJECT CHOICES ENABLED: FALSE"
        end
        puts "PROJECT CHOICES: "
        puts session[:new_project_data][:project_choices]
        puts "PROJECT ALLOC METHOD: " + params[:project_allocation_method]
        puts "---------------------------"
        puts "TEAM SIZE: " + params[:team_size]
        puts "TEAM ALLOC METHOD: " + params[:team_allocation_method]
        puts "PREFERRED TEAMMATES: " + params[:preferred_teammates]
        puts "AVOIDED TEAMMATES: " + params[:avoided_teammates]
        puts "---------------------------"
        puts "PROJECT DEADLINE: " + params[:project_deadline]
        puts "TEAMMATES PREF FROM DEADLINE: " + params[:teammate_preference_form_deadline]
        puts "PROJECT PREF FORM DEADLINE: " + params[:project_preference_form_deadline]

        params.each do |key, value|
            # Check if the key starts with "milestone_"
            if key.match?(/^milestone_[^_]+_date$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]
          
                # Find the corresponding milestone in the milestones hash and update its "Date" value
                if milestone = session[:new_project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    milestone[:Date] = value
                end
            end
        end
        puts "MILESTONES:"
        puts session[:new_project_data][:project_milestones]

        render :new
    end
end
