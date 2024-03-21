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
    end
end
