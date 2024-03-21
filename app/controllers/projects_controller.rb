class ProjectsController < ApplicationController

    def index
        @view_as_manager = true
        if @view_as_manager            
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def new
        @project_choices = ["Mental Health Chatbot", "Software Hut Meta Project"]
    end

    def new_project_add_project_choice
        project_choice_name = params[:project_choice_name]
        puts "Project choice name: #{project_choice_name}"
    end
end
