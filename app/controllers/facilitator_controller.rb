# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class FacilitatorController < ApplicationController
  skip_authorization_check

  # For each progress form route we check if the user is a facilitator for the project of the targeted team
  # This has to be done as the relationship being AssignedFacilitators and Groups is misconfigured

  def index
    authorize! :read, :facilitator
    # Get assigned groups
    @groups = get_assigned_groups
    @assigned_projects = get_assigned_projects
  end

  def update_teams_list
    authorize! :read, :facilitator
    @assigned_projects = get_assigned_projects

    # Apply filters to the shown teams
    if params[:assigned_only]
      @groups = get_assigned_groups

    else
      # I am assuming here that a facilitator will only be asked to facilitate for teams in projects
      # that they're already a facilitator for.
      @groups = Group.where(course_project_id: get_assigned_projects.map(&:id))
    end

    unless params[:projects_filter] == "All" || params[:projects_filter].empty?
      target_project_id = CourseProject.find_by(name: params[:projects_filter]).id
      @groups = @groups.select { |g| g.course_project_id == target_project_id }
    end

    render partial: "teams-list-card"
  end

  def progress_form
    set_current_group
    authorize! :facilitator_team, @current_group

    # Get the progress form to fill in
    @progress_form = Milestone.find(params[:milestone_id].to_i)

    if @progress_form.nil?
      flash.alert = "Could not find progress form."
      redirect_to action: :index
      return
    end

    session[:progress_form_id] = @progress_form.id

    # Try find a pre-existing response
    @progress_response = @progress_form.milestone_responses.select do |mr|
      mr.json_data["group_id"] == @current_group.id
    end.first
  end

  def team
    # Display team/group area
    set_current_group
    authorize! :facilitator_team, @current_group

    # Get progress forms and sort by release date
    @progress_forms = get_progress_forms_for_group.sort_by(&:deadline)

    # Split into sections
    @progress_forms_submitted = @progress_forms.select do |pf|
      pf.milestone_responses.select do |mr|
        mr.json_data["group_id"] == @current_group.id
      end.length.positive?
    end

    @progress_forms_todo = @progress_forms - @progress_forms_submitted

    @chat_messages = @current_group.events.where(event_type: :chat).order(created_at: :asc) unless @current_group.nil?

    logger.debug "!!!!!!!!!!!!!!!!! #{@chat_messages}"
  end

  def update_progress_form_response
    set_current_group
    authorize! :facilitator_team, @current_group
    @progress_form = Milestone.find(session[:progress_form_id])

    # Try find existing response to update
    @progress_response = @progress_form.milestone_responses.select do |mr|
      mr.json_data["group_id"] == @current_group.id
    end.first

    # Create new response if none to update
    if @progress_response.nil?
      @progress_response = MilestoneResponse.new(
        json_data:    {
          group_id:           @current_group.id,
          attendance:         params[:attendance],
          question_responses: params[:question_responses],
          facilitator_repr:   get_facilitator_repr(
            get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first
          )
        },
        milestone_id: @progress_form.id
      )
    else
      @progress_response.json_data[:attendance] = params[:attendance]
      @progress_response.json_data[:question_responses] = params[:question_responses]
      @progress_response.json_data[:facilitator_repr] = get_facilitator_repr(
        get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first
      )
    end

    unless @progress_response.save
      return render json: { status: "error", message: "Failed to save progress form response." }
    end

    render json: { status: "success", redirect: facilitator_team_facilitators_path(team_id: session[:team_id]) }
  end

  private
    def get_assigned_facilitators
      # Returns the entries of AssignedFacilitator for the logged in user
      if current_user.is_admin?
        AssignedFacilitator.all
      elsif current_user.is_staff?
        AssignedFacilitator.where(staff: current_user.staff)
      elsif current_user.is_student?
        AssignedFacilitator.where(student: current_user.student)
      end
    end

    def get_assigned_groups
      # Return all the groups that the current user is facilitating
      get_assigned_facilitators.flat_map(&:groups)
    end

    def get_assigned_projects
      # Returns all the projects the current user is facilitating
      get_assigned_facilitators.map(&:course_project).uniq
    end

    def set_current_group
      # Team id will always be provided unless ajax request, then just use the cached one.
      session[:team_id] = params[:team_id] unless params[:team_id].nil?

      @current_group = Group.find(session[:team_id])
      @current_group_facilitator_repr = get_facilitator_repr(@current_group.assigned_facilitator)
    end

    def get_facilitator_repr(facilitator)
      return "" if facilitator.nil?

      if facilitator.student_id
        Student.find_by(id: facilitator.student_id).email

      elsif facilitator&.staff_id
        Staff.find_by(id: facilitator.staff_id).email
      end
      end

    def get_progress_forms_for_group
      # Return released progress forms for group
      Milestone.select do |m|
        m.json_data["name"] == "progress_form" &&
          m.deadline <= DateTime.current &&
          m.course_project_id == @current_group.course_project_id
      end
    end

  # def authorise_facilitator
  #   set_current_group
  #   return if @current_group.nil?
  #   project_id = @current_group


  # end
end
