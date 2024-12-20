# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CourseModuleController < ApplicationController
  authorize_resource

  before_action :set_module, only: %i[show edit update destroy]

  # GET /modules
  def index
    @admin_modules = if current_user.is_admin?
      CourseModule.all
    else
      CourseModule.where(staff_id: current_user.staff)
    end

    @show_create_button = current_user.is_admin?
  end

  # GET /modules/new
  def new
    @new_module = CourseModule.new
  end

  # POST /modules
  def create
    # Checks for unique module code
    unless CourseModule.where(code: (params[:course_module][:code]).strip).empty?
      redirect_to new_module_path, alert: "The Module Code is already in use."
      return
    end

    # Checks for correct e-mail confirmation
    @lead = params[:new_module_lead_email]

    @confirmation = params[:new_module_lead_email_confirmation]
    unless @lead == @confirmation
      redirect_to new_module_path, alert: "Unsuccesful - E-mail addresses did not match."
      return
    end

    # Creates new staff account if no staff found in system
    @lead = Staff.find_or_create_by(email: @lead)

    # Checks that the student_csv is compatible with the created module
    unless params[:student_csv].nil?
      @student_csv = CSV.read(params[:student_csv].tempfile)
      unless @student_csv[1][12] == params[:course_module][:code]
        redirect_to new_module_path,
                    alert: "The Student List Module {#{@student_csv[1][12]}} is not compatible with the Module Code {#{params[:course_module][:code]}}"
        return
      end
    end

    # Creates new module
    @new_module = CourseModule.new(code: params[:course_module][:code], name: params[:course_module][:name],
                                   staff_id: @lead.id)
    if @new_module.save
      Student.bootstrap_class_list(params[:student_csv].read) unless @student_csv.nil?
      redirect_to modules_path, notice: "Module was successfully created."
    else
      redirect_to new_module_path, alert: "Creation unsuccesful."
    end
  end

  # GET /modules/{id}
  def show
    @students = @current_module.students
    @module_lead = @current_module.staff
    @updated = @current_module.updated_at.strftime("%H:%M %d/%m/%Y")
    @created = @current_module.created_at.strftime("%H:%M %d/%m/%Y")

    @show_edit_buttons = current_user.is_admin?
  end

  # PATCH/PUT /modules/{id}
  def update
    @new_name = params[:new_module_name]
    @new_lead = params[:new_module_lead_email]
    @confirmation = params[:new_module_lead_email_confirmation]
    @new_student_list = params[:new_module_student_list]

    # Update Module Name modal
    unless @new_name.nil?
      @current_module.update_attribute(:name, @new_name)

      if @current_module.valid?
        redirect_to module_path, notice: "Module Name updated successfully."
      else
        redirect_to module_path, alert: "Update unsuccessful - Invalid name."
      end
    end

    # Update Module Lead modal
    unless @new_lead.nil?

      # Checks for correct e-mail confirmation
      unless @new_lead == @confirmation
        redirect_to module_path, alert: "Update unsuccesful - E-mail addresses did not match."
        return
      end

      # Creates new staff account if no staff found in system
      @new_lead = Staff.find_or_create_by(email: @new_lead)

      @current_module.update_attribute(:staff_id, @new_lead.id)

      if @current_module.valid?
        redirect_to module_path, notice: "Module Leader updated successfully."
      else
        redirect_to module_path, alert: "Update unsuccesful - Invalid e-mail."
      end
    end

    # Update Module Student List modal
    return if @new_student_list.nil?

    # Checks that the student_csv is compatible with the current module
    @parsed_csv = CSV.read(@new_student_list)
    unless @parsed_csv[1][12] == @current_module.code
      redirect_to module_path,
                  alert: "The Student List Module {#{@parsed_csv[1][12]}} is not compatible with the Module Code {#{@current_module.code}}"
      return
    end

    # Removes old student list and adds new one
    @current_module.students.clear
    Student.bootstrap_class_list(@new_student_list.read)
    redirect_to module_path, notice: "Student List updated successfully."
  end

  def delete
    course_module = CourseModule.find(params[:id])
    if course_module.destroy
      flash[:notice] = "Module successfully deleted"
      redirect_to modules_path
    else
      flash[:error] = "An error occurred"
    end
  end

  private
    def set_module
      @current_module = CourseModule.find(params[:id])
    end

    def module_params
      params.require(:course_module).permit(:code, :name, :staff_id, :student_csv)
    end
end
