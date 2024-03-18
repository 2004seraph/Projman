class FacilitatorsController < ApplicationController
    # GET /facilitators 
    def index
        @my_teams = Array.new(5) {|i| i.to_s }
        @my_marking_modules = ["COM1001", "COM2002", "COM3003", "COM4004"]
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

    
end