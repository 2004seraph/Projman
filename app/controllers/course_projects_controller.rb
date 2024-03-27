class CourseProjectsController < ApplicationController

    def index
        @view_as_manager = true
        if @view_as_manager            
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def new
        puts "CREATING NEW PROJECT"
        @project = CourseProject.new
        @modules_hash = CourseModule.order(:code).pluck(:code, :name).to_h
        @project_allocation_modes_hash = CourseProject.project_allocations
        puts @project_allocation_modes_hash
        
    end

    # POST
    def new_project_add_project_choice
        project_choice_name = params[:project_choice_name]
        puts "Project choice name: #{project_choice_name}"
    end
end
