# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MarkingController < ApplicationController
  load_and_authorize_resource :milestone_response

  def index
    # Get all mark schemes to filter
    all_mark_schemes = Milestone.select { |m| m.system_type == 'marking_deadline' }

    # Get all the mark schemes assigned to
    @mark_schemes = []
    all_mark_schemes&.each do |ms|
      ms.json_data['sections']&.each do |section|
        if section['assessors']&.keys&.include?(current_user.email)
          @mark_schemes << ms
          break
        end
      end
    end
  end

  def new
    mark_scheme = Milestone.find(params[:milestone_id].to_i)

    @section = mark_scheme.json_data['sections'][params[:section_index].to_i]
    @mark_scheme_project = mark_scheme.course_project

    session[:mark_scheme_id] = mark_scheme.id
    session[:mark_scheme_section_index] = params[:section_index].to_i

    @assigned_teams = @section['assessors'][current_user.email].map { |id| Group.find(id) }
    @assigned_teams_ids = @assigned_teams.flat_map(&:id)

    # Load marking responses for teams
    @team_marks = mark_scheme.milestone_responses.select do |mr|
      @assigned_teams_ids.include?(mr.json_data['group_id'])
    end
  end

  def save
    marking = params[:marking]

    mark_scheme = Milestone.find(session[:mark_scheme_id])

    section = mark_scheme.json_data['sections'][session[:mark_scheme_section_index]]
    assessor = current_user.email
    group_ids = section['assessors'][assessor]

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
        if response.json_data['sections'][section['title']].nil?
          response.json_data['sections'][section['title']] =
            {}
        end

        response.json_data['sections'][section['title']]['marks_given'] = marks_given
        response.json_data['sections'][section['title']]['reason'] = reason
        response.json_data['sections'][section['title']]['assessor'] = assessor
      end

      success = false unless response.save
    end

    return render json: { status: 'success', redirect: markings_path } if success

    render json: { status: 'error', message: 'Failed to save marking.' }
  end
end

