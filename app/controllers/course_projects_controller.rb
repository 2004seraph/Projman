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
# [ {"Name": "Technical Review", "Date": "dd-mm-yyyy"}, 
#   {"Name": "Peer Review", "Date: "dd-mm-yyyy"}]

class CourseProjectsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:new_project_remove_project_choice, :new_project_clear_facilitator_selection]

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
        puts project_allocation_modes_hash

        session[:new_project_data] = {
            modules_hash: modules_hash,
            project_allocation_modes_hash: project_allocation_modes_hash,
            project_choices: ["Example Choice 1"],
            project_milestones: [],
            facilitator_selection: [],
            project_facilitators: []
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
        session[:new_project_data][:project_milestones] << {"Name": @project_milestone_name, "Date": ""}
        if request.xhr?
            respond_to do |format|
                format.js
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
end
