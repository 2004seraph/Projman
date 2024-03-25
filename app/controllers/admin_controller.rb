class AdminController < ApplicationController
    before_action :set_module, only: %i[ show edit update destroy ]

    #GET /admin
    def index
        @admin_modules = CourseModule.all
    end

    #GET /admin/new
    def new
    end

    #GET /admin/{id}
    def show
        @students = @current_module.students
        @module_lead = @current_module.staff
    end

    #PATCH/PUT /admin/{id}
    def update
        @new_lead = Staff.where(email: params[:new_module_lead_email]).first

        if @new_lead.nil?
            redirect_to admin_path, alert: "Update unsuccesful - invalid e-mail."
        else
            @current_module.update_attribute(:staff_id, @new_lead.id)
            if @current_module.valid?
                redirect_to admin_path, notice: "Module Leader updated successfully."
            else
                redirect_to admin_path, alert: "Update unsuccesful - invalid e-mail"
            end
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_module
      @current_module = CourseModule.find(params[:id])
    end

end