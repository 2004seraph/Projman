# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class StudentController < ApplicationController
  load_and_authorize_resource
  helper_method :update_selection

  def index
    session[:module_data] = {
      errors: {},
      module_code: -1,
      module_students: [],
      student_selection: [],
    }
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
    course_module = CourseModule.find_by(code: session[:module_data][:module_code])

    @results = Student.where('email LIKE ?', "%#{query}%")
                      .where.not(id: course_module.students.pluck(:id))
                      .limit(8)
                      .distinct
    render json: @results.pluck(:email)
  end

  def confirm_selection
    to_add = []
    @students_added = []
    @module_code = session[:module_data][:module_code]
    session[:module_data][:student_selection].each do |stud|
      to_add << stud
    end
    to_add.each do |user_email|
      next unless session[:module_data][:module_code].is_a?(String)

      if Student.exists?(email: user_email)
        s = Student.find_by(email: user_email)
        next unless s.enroll_module(session[:module_data][:module_code])

        @students_added << s
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

  def remove_students_from_module
    student_emails = params[:emails]
    removed_student_emails = []
    module_code = session[:module_data][:module_code]
    m = CourseModule.find_by(code: module_code)
    unless m.nil?
      student_emails.each do |email|
        s = m.students.find_by(email:)
        next if s.nil?

        m.students.delete(s)
        m.course_projects.each do |p|
          p.groups.each do |g|
            if g.students.include?(s)
              g.students.delete(s)
              removed_student_emails << email
            end
          end
        end
      end
    end

    response_json = {
      removed_student_emails:,
      module_code:
    }
    render json: response_json
  end
end
