class FacilitatorController < ApplicationController
    # GET /facilitators 
    def index
    end

    

    # GET /facilitators/team/{id}
    def team
        @team = params[:id]
        @members = ["Oliver Pickford", "Jack Sparrow"]
        @emails = ["opickford1@sheffield.ac.uk", "jacksparrow1@sheffield.ac.uk"]

    end

    # GET /facilitators/marking/{module}
    def marking
        @marking = params[:module]
    end

    def projects
        #@facilitator_projects = CourseProject.all
        
        # TEMP: Using modules as no courseprojects yet
        @facilitator_projects = CourseModule.all
    end

    def projects_show
    end
end