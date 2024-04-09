class FacilitatorController < ApplicationController
    skip_authorization_check # TEMP: Not sure why needed.

    # GET /facilitators 
    def index
    end

    # GET /facilitators/marking/{module}
    def marking
        @marking = params[:module]
    end

    def projects
        #@facilitator_projects_temp = CourseProject.all
        # TEMP: Using modules as no courseprojects yet
        @facilitator_projects = CourseModule.all
    end

    def projects_show
    end

    def progress_form
    end
end