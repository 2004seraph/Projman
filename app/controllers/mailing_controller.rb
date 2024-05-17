# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MailingController < ApplicationController
  authorize_resource class: false

  CONTACT_METHOD = 0
  SUBJECT = 1
  BODY = 2

  STUDENTS_IN_MODULE_CONTACT_METHOD = "students_in_module"
  TEAMS_ON_PROJECT_CONTACT_METHOD = "teams_on_project"
  CUSTOM_LIST_CONTACT_METHOD = "custom_list"

  def mail
    @last_contact_method =
      params[:contact_method] ||
      session[:mailing_form_last_contact_method] ||
      "custom_list"

    if current_user.is_admin?
      @modules = CourseModule.all
    else
      @modules = current_user.staff.course_modules
    end
    @selected_module = nil
    @selected_module = params[:module_selection] || @modules.first if @modules.count > 0

    if current_user.is_admin?
      @projects = CourseProject.all
    else
      @projects = current_user.staff.course_projects
    end
    @selected_project = nil
    @selected_project = params[:project_selection] || @projects.first if @projects.count > 0

    @email_list = params[:recipient_list] || ""
  end

  def create
    # {"authenticity_token"=>"uKfofLxRbHU36dRfvZYcp-bOa0bJm52qhtxwXDGB6elIkPi1KlJOznYo5fa1rQ-Vy5qZWXzY-UFROY98XnfRsQ", "module_selection"=>"1", "project_selection"=>"1", "contact_method"=>"custom_list", "recipient_list"=>"sgsdfghd", "email_body"=>"zdfxbzdsgs", "controller"=>"mailing", "action"=>"create"}

    return email_failiure "Invalid email format" unless base_params

    session[:mailing_form_last_contact_method] = base_params[CONTACT_METHOD]

    case base_params[CONTACT_METHOD]
    when STUDENTS_IN_MODULE_CONTACT_METHOD
      if module_selection_valid?
        students = CourseModule.find(params[:module_selection]).students

        students.each do |student|
          MessageMailer.individual_message(current_user, student.email, base_params[SUBJECT], base_params[BODY]).deliver_later
        end

        email_successful
      else
        return email_failiure "Invalid module selection"
      end
    when TEAMS_ON_PROJECT_CONTACT_METHOD
      if project_selection_valid?
        project = CourseProject.find(params[:project_selection])
        students = project.students

        students.each do |student|
          MessageMailer.individual_message(current_user, student.email, base_params[SUBJECT], base_params[BODY], project).deliver_later
        end

        email_successful
      else
        return email_failiure "Invalid project selection"
      end
    when CUSTOM_LIST_CONTACT_METHOD
      if recipient_list_valid?
        emails = CSV.parse(params[:recipient_list].delete("\n").strip, headers: false)

        # validate emails
        emails[0].each do |email|
          return email_failiure "Invalid recipient email: #{email}" unless DatabaseHelper::EMAIL_REGEX.match? email
        end

        emails[0].each do |email|
          MessageMailer.individual_message(current_user, email, base_params[SUBJECT], base_params[BODY]).deliver_later
        end

        email_successful
      else
        return email_failiure "Invalid recipient list"
      end
    end

    redirect_to mail_path
  end

  private
    def email_successful
      flash[:notice] = "Email sent successfully"
    end
    def email_failiure(msg)
      flash[:alert] = msg
      redirect_to mail_path
      nil
    end

    def base_params
      params.require([:contact_method, :email_subject, :email_body])
    rescue
      false
    end
    def recipient_list_valid?
      params[:recipient_list] and params[:recipient_list].length > 0
    end
    def module_selection_valid?
      c_id = Integer(params[:module_selection]) rescue false

      params[:module_selection] and
      c_id and
      CourseProject.exists?(c_id) and
      CourseProject.find(c_id).staff == current_user.staff
    end
    def project_selection_valid?
      c_id = Integer(params[:project_selection]) rescue false

      params[:project_selection] and
      c_id and
      CourseProject.exists?(c_id) and
      CourseProject.find(c_id).staff == current_user.staff
    end
end
