class AdminController < ApplicationController
    
    #GET /admin
    def index
        @admin_modules = CourseModule.all
    end

    #GET /admin/new
    def new
    end

    #GET /admin/show/{id}
    def show
        @current_module = CourseModule.find(params[:id])
        @students = @current_module.students
        @module_lead = Staff.find(@current_module.staff_id)
    end

end