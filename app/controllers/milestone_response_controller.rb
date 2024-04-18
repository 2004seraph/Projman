class MilestoneResponseController < ApplicationController
    load_and_authorize_resource

    def create
        redirect_to '/projects', notice: "#{params[:author]}. #{params[:project_id]}"
    end

    private

    def milestone_response_params
    end

end
