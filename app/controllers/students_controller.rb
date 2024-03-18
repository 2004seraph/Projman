class StudentsController < ApplicationController

    view_as_manager = true
    def index
        render 'index', formats: [:html]
    end
end
