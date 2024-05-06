# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class StudentController < ApplicationController
  # load_and_authorize_resource
  skip_authorization_check
  helper_method :update_selection

  def index
    session[:module_data] = {
      errors: {},
      module_code: -1,
      module_students: [],
      student_selection: [],
    }
=begin
    Student.find_by(email: "awillis4@sheffield.ac.uk").unenroll_module("COM2108")
    Student.find_by(email: "sgttaseff1@sheffield.ac.uk").unenroll_module("COM2108")
    Student.find_by(email: "jbala1@sheffield.ac.uk").unenroll_module("COM2108")
    Student.find_by(email: "nkhan10@sheffield.ac.uk").unenroll_module("COM2108")
    Student.find_by(email: "opickford1@sheffield.ac.uk").unenroll_module("COM2108")
=end
  end

  def update_selection
    @student_email = params[:module_student_name]
    session[:module_data][:student_selection] << @student_email if @student_email.present?
    puts session[:module_data][:student_selection]
    if request.xhr?
      respond_to(&:js)
    else
      render :index
    end
  end
  def search_students
    query = params[:query]
    @results = Student.where('email LIKE ?', "%#{query}%").limit(8).distinct
    render json: @results.pluck(:email)
  end
  def confirm_selection
    to_add = []
    @students_added = []
    session[:module_data][:student_selection].each do |stud|
      unless session[:module_data][:module_students].include?(stud)
        session[:module_data][:module_students] << stud
        to_add << stud
        @students_added << stud
      end
    end    
    for user_email in to_add do
      if Student.exists?(email: user_email) && session[:module_data][:module_code].is_a?(String)
        Student.find_by(email: user_email).enroll_module(session[:module_data][:module_code])
      end
    end
    if request.xhr?
      respond_to(&:js)
    else
      render :index
    end
  end
  def clear_selection
    session[:module_data][:student_selection] = []
  end
  def clear_student
    @student_email = params[:item_text]
    session[:module_data][:student_selection].delete(@student_email)
  end
  
  def remove_student_from_module
  
  end
end

