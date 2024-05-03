# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class FacilitatorController < ApplicationController
  authorize_resource :milestone_response

  def index
    # Get assigned groups
    @assigned_facilitators = get_assigned_facilitators
    set_assigned_projects

    # Get all mark schemes to filter
    all_mark_schemes = Milestone.select { |m| m.system_type == 'marking_deadline' }
    return if all_mark_schemes.nil?

    # Get all the mark schemes assigned to
    @mark_schemes = []

    all_mark_schemes.each do |ms|
      ms.json_data['sections']&.each do |section|
        if section['facilitators']&.keys&.include?(current_user.email)
          @mark_schemes << ms
          break
        end
      end
    end
  end

  def update_teams_list
    authorize! :read, :facilitator

    # Apply filters to the shown teams
    if params[:assigned_only]
      @assigned_facilitators = get_assigned_facilitators

    else
      # I am assuming here that a facilitator will only be asked to facilitate for teams in projects
      # that they're already a facilitator for.
      facilitator_project_ids = get_assigned_facilitators.map(&:course_project_id)
      @assigned_facilitators = AssignedFacilitator.where(course_project_id: facilitator_project_ids)
    end

    unless params[:projects_filter] == 'All' || params[:projects_filter].empty?
      target_project_id = CourseProject.find_by(name: params[:projects_filter]).id
      @assigned_facilitators = @assigned_facilitators.where(course_project_id: target_project_id)
    end

    set_assigned_projects
    render partial: 'teams-list-card'
  end

  def progress_form
    authorize! :read, :facilitator

    set_current_group

    # Get the progress form to fill in
    @progress_form = Milestone.find(params[:milestone_id].to_i)

    if @progress_form.nil?
      flash.alert = 'Could not find progress form.'
      redirect_to action: :index
      return
    end

    session[:progress_form_id] = @progress_form.id

    # Try find a pre-existing response
    @progress_response = @progress_form.milestone_responses.select do |mr|
      mr.json_data['group_id'] == @current_group.id
    end.first
  end

  def marking_show
    authorize! :read, :facilitator

    mark_scheme = Milestone.find(params[:milestone_id].to_i)

    @section = mark_scheme.json_data['sections'][params[:section_index].to_i]
    @mark_scheme_project = CourseProject.find(mark_scheme.course_project_id)

    session[:mark_scheme_id] = mark_scheme.id
    session[:mark_scheme_section_index] = params[:section_index].to_i

    @assigned_teams = @section['facilitators'][current_user.email].map { |id| Group.find(id) }
    @assigned_teams_ids = @assigned_teams.flat_map(&:id)

    # Load marking responses for teams
    @team_marks = mark_scheme.milestone_responses.select do |mr|
      @assigned_teams_ids.include?(mr.json_data['group_id'])
    end
  end

  def team
    # Display team/group area
    set_current_group
    authorize! :read, :facilitator

    # Get progress forms and sort by release date
    @progress_forms = get_progress_forms_for_group.sort_by(&:deadline)

    # Split into sections
    @progress_forms_submitted = @progress_forms.select do |pf|
      pf.milestone_responses.select do |mr|
        mr.json_data['group_id'] == @current_group.id
      end.length.positive?
    end

    @progress_forms_todo = @progress_forms - @progress_forms_submitted
  end

  def update_progress_form_response
    set_current_group

    @progress_form = Milestone.find(session[:progress_form_id])

    # Try find existing response to update
    @progress_response = @progress_form.milestone_responses.select do |mr|
      mr.json_data['group_id'] == @current_group.id
    end.first

    # Create new response if none to update
    if @progress_response.nil?
      @progress_response = MilestoneResponse.new(
        json_data: {
          group_id: @current_group.id,
          attendance: params[:attendance],
          question_responses: params[:question_responses],
          facilitator_repr: get_facilitator_repr(
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
      return render json: { status: 'error', message: 'Failed to save progress form response.' }
    end

    render json: { status: 'success', redirect: facilitator_team_facilitators_path(team_id: session[:team_id]) }
  end

  def update_marking
    marking = params[:marking]

    mark_scheme = Milestone.find(session[:mark_scheme_id])

    section = mark_scheme.json_data['sections'][session[:mark_scheme_section_index]]
    group_ids = section['facilitators'][current_user.email]
    assessor = current_user.email

    # For each group, try and update the milestone response containing their marking
    success = true
    group_ids.each do |group_id|
      group = Group.find(group_id)

      marks_given = marking[group_id.to_s][0]
      reason = marking[group_id.to_s][1]

      # Look for pre-existing marking for the group
      response = mark_scheme.milestone_responses.select { |ms| ms.json_data['group_id'] == group.id }.first

      if response.nil?
        response = MilestoneResponse.new(
          json_data: {
            "sections": {
              section['title'] => {
                'marks_given' => marks_given,
                'reason' => reason,
                'assessor' => assessor
              }
            },
            "group_id": group.id
          },
          milestone_id: mark_scheme.id
        )
      else
        # Using title as primary key for section as sections can be deleted.
        response.json_data['sections'][section['title']] = {} if response.json_data['sections'][section['title']].nil?

        response.json_data['sections'][section['title']]['marks_given'] = marks_given
        response.json_data['sections'][section['title']]['reason'] = reason
        response.json_data['sections'][section['title']]['assessor'] = assessor
      end

      success = false unless response.save
    end

    return render json: { status: 'success', redirect: facilitators_path } if success

    render json: { status: 'error', message: 'Failed to save marking.' }
  end

  private

  def get_assigned_facilitators
    # Returns the entries of AssignedFacilitator for the logged in user
    if current_user.is_staff?
      AssignedFacilitator.where(staff: current_user.staff)

    elsif current_user.is_student?
      AssignedFacilitator.where(student: current_user.student)
    end
  end

  def set_assigned_projects
    @assigned_projects = get_assigned_facilitators.flat_map(&:course_project)
  end

  def set_current_group
    # Team id will always be provided unless ajax request, then just use the cached one.
    session[:team_id] = params[:team_id] unless params[:team_id].nil?

    @current_group = Group.find(session[:team_id])
    @current_group_facilitator_repr = get_facilitator_repr(@current_group.assigned_facilitator)
  end

  def get_facilitator_repr(facilitator)
    if facilitator.student_id
      Student.find_by(id: facilitator.student_id).email

    elsif facilitator.staff_id
      Staff.find_by(id: facilitator.staff_id).email
    end
  end

  def get_progress_forms_for_group
    # Return released progress forms for group
    Milestone.select do |m|
      m.json_data['name'] == 'progress_form' &&
        m.deadline <= DateTime.current &&
        m.course_project_id == @current_group.course_project_id
    end
  end
end
