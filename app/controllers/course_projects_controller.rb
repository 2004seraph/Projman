require 'json'

class CourseProjectsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:new_project_remove_project_choice]

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
            project_choices: ["Example Choice 1"]
        }
    end

    # POST
    def new_project_add_project_choice
        puts "SUBMITTED NEW PROJECT CHOICE"
        @project_choice_name = params[:project_choice_name]
        session[:new_project_data][:project_choices] << @project_choice_name
        puts "Project Choices: "
        puts session[:new_project_data][:project_choices]

        # If done via AJAX (JavaScript enabled), dynamically add
        if request.xhr?
            puts "SUBMITTED AS AJAX"
            respond_to do |format|
                format.js
            end

        # Otherwise re-render :new
        else
            render :new
        end
    end

    def new_project_remove_project_choice
        @project_choice_name = params[:item_text]
        puts "DELETING: "
        puts @project_choice_name
        session[:new_project_data][:project_choices].delete(@project_choice_name)
        puts "Project Choices: "
        puts session[:new_project_data][:project_choices]
        if request.xhr?
            puts "SUBMITTED AS AJAX"
        else
            render :new
        end
    end
end
