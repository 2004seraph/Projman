class IssuesController < ApplicationController
    # load_and_authorize_resource

    def index
        @view_as_manager = false
        if @view_as_manager            
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end
end
