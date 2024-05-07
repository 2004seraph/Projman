# frozen_string_literal: true

class GroupController < ApplicationController
  load_and_authorize_resource

  def index
    puts "INDEX ACTION"
    @current_project = CourseProject.find(params[:project_id])
    puts @current_project
    @teams = []
    return if @current_project.nil?

    @teams = @current_project.groups.order(id: :asc)
    puts @teams.pluck(:assigned_facilitator_id)
    render 'group/index'
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
        rendered_partial = render_to_string(partial: 'group/facilitator_option', locals: { id: f.id, name: f.id, email: f.email })
        response_partials << rendered_partial
      end
    end

    json_response = {
      facilitator_emails: project_facilitators.present? ? project_facilitators.pluck(:email) : [],
      team_facilitator: group_facilitator&.email,
      partials: response_partials
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
        g&.assigned_facilitator_id = project.assigned_facilitators&.find_by(staff_id: staff_id)&.id
      elsif Student.exists?(email: facilitator_email)
        student_id = Student.find_by(email: facilitator_email).id
        g&.assigned_facilitator_id = project.assigned_facilitators&.find_by(student_id: student_id)&.id
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
end
