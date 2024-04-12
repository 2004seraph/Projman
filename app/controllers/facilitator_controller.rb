class FacilitatorController < ApplicationController
    # GET /facilitators 
    def index
    end

    # GET /facilitators/marking/{module}
    def marking
        @marking = params[:module]
    end

    def projects
        #@facilitator_projects_temp = CourseProject.all
        #puts "projects count: " + @facilitator_projects_temp.length.to_s
        # TEMP: Using modules as no courseprojects yet
        @facilitator_projects = CourseModule.all
    end

    def projects_show
        @facilitator_project = CourseProject


    end

    def progress_form
    end
end