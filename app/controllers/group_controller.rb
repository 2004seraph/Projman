# frozen_string_literal: true

class GroupController < ApplicationController
  skip_authorization_check only: [:index]
  load_and_authorize_resource except: [:index]

  def index
    @current_project = CourseProject.find(params[:project_id])
    authorize! :update, @current_project

    # Rails.logger.debug "INDEX ACTION"
    # Rails.logger.debug @current_project
    @teams = []
    return if @current_project.nil?

    @teams = @current_project.groups.order(id: :asc)

    student_list = @current_project.students.to_a
    @teams.each do |team|
      team.students.each do |student|
        student_list.reject! { |s| s == student }
      end
    end
    @outstanding_students = student_list

    # Rails.logger.debug @teams.pluck(:assigned_facilitator_id)
    render "group/index"
  end

  def facilitator_emails
    project_id = params[:project_id]
    team_id = params[:team_id]
    p = CourseProject.find_by(id: project_id)
    g = Group.find_by(id: team_id)
    project_facilitators = p&.facilitators
    group_facilitator = g&.facilitator

    response_partials = []

    if project_facilitators.present?
      project_facilitators.each do |f|
        rendered_partial = render_to_string(partial: "group/facilitator_option",
                                            locals:  { id: f.id,
name: f.id, email: f.email })
        response_partials << rendered_partial
      end
    end

    json_response = {
      facilitator_emails: project_facilitators.present? ? project_facilitators.pluck(:email) : [],
      team_facilitator:   group_facilitator&.email,
      partials:           response_partials
    }
    render json: json_response
  end

  def set_facilitator
    project_id = params[:project_id]
    team_id = params[:id]
    facilitator_email = params[:facilitator_email]
    project = CourseProject.find_by(id: project_id)
    project_facilitator_emails = project.facilitators.present? ? project.facilitators.pluck(:email) : []

    no_errors = false
    if project&.groups&.ids&.include?(team_id.to_i) && project_facilitator_emails.include?(facilitator_email)

      g = project.groups&.find(team_id)
      if Staff.exists?(email: facilitator_email)
        staff_id = Staff.find_by(email: facilitator_email).id
        g&.assigned_facilitator_id = project.assigned_facilitators&.find_by(staff_id:)&.id
      elsif Student.exists?(email: facilitator_email)
        student_id = Student.find_by(email: facilitator_email).id
        g&.assigned_facilitator_id = project.assigned_facilitators&.find_by(student_id:)&.id
      end
      if g.valid?
        g.save!
        g.reload
        project.reload
        no_errors = true
        @team_id = team_id
        @facilitator_email = facilitator_email
      else
        no_errors = false
      end

    end
    respond_to(&:js) if no_errors
  end

  def current_subproject
    project_id = params[:project_id]
    team_id = params[:id]
    project = CourseProject.find_by(id: project_id)
    g = project&.groups&.find_by(id: team_id)
    subproject_name = g&.subproject&.name
    json_response = {
      current_subproject_name: subproject_name
    }
    render json: json_response
  end

  def set_subproject
    team_id = params[:id]
    subproject_name = params[:subproject_name]

    g = Group.find_by(id: team_id)
    p = g&.course_project
    g&.subproject = p&.subprojects&.find_by(name: subproject_name)
    no_errors = false
    if g.valid?
      g.save!
      no_errors = true
      @team_id = team_id
      @project_choice_name = subproject_name
    else
      no_errors = false
    end

    respond_to(&:js) if no_errors
  end

  def search_module_students
    query = params[:query]
    course_module = CourseModule.find_by(code: session[:module_data][:module_code])

    @results = Student.where("email LIKE ?", "%#{query}%")
                      .where(id: course_module.students.pluck(:id))
                      .limit(8)
                      .distinct
    render json: @results.pluck(:email)
  end

  def add_student_to_team
    team_id = params[:id]
    team = Group.find_by(id: team_id)
    project = team&.course_project
    student = project.course_module.students&.find_by(email: params[:student_email])

    @student = student
    @team = team
    @team_id = team_id

    Rails.logger.debug "ADDING TO TEAM #{team.name}"

    if student
      # check if they are in a group on this project. if so, remove them
      project&.groups&.each do |group|
        next unless group.students&.include?(student)

        Rails.logger.debug "REMVOING FORM #{group.name}"
        group.students.delete(student)
        @removed_student_from_group = group.id
        break
      end
      # add them to the team
      team.students << student
      team.save if team.valid?
    end

    respond_to(&:js)
  end

  def remove_students_from_team
    student_emails = params[:emails]
    removed_student_emails = []
    p = CourseProject.find_by(id: params[:project_id])
    g = p&.groups&.find_by(id: params[:id])
    unless g.nil?
      student_emails.each do |email|
        s = g.students&.find_by(email:)
        next if g&.nil?

        g.students.delete(s)
        removed_student_emails << email
      end
    end

    response_json = {
      removed_student_emails:
    }
    render json: response_json
  end
end
