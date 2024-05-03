# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class ProgressFormController < ApplicationController
  authorize_resource :milestone_response

  def index
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    authorize! :read, @current_project

    # Get each progress form
    @progress_forms = get_progress_forms_for_project.sort_by(&:deadline)

    # Auto select the one with the furthest release date
    @progress_form = @progress_forms.last
    session[:progress_form_id] = @progress_form.nil? ? -1 : @progress_form.id
  end

  def new
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    # Initialise new form
    # NOTE: Will not work without parse and to_json because its loaded from db as json
    #       so this just keeps it always as json.
    session[:new_progress_form] = JSON.parse({
      "questions": [],
      "attendance": true
    }.to_json)

    session[:progress_form_deadline] = ''

    @progress_form_json = session[:new_progress_form]
    @progress_form_deadline = ''
  end

  def edit
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    progress_form = Milestone.find(params[:id])
    if progress_form.nil?
      flash.alert = 'Could not find progress form to edit.'

      redirect_to project_progress_form_index_path
      return
    end

    # Can't edit released forms
    if progress_form.deadline <= DateTime.current
      flash.alert = 'Cannot edit a released form.'
      redirect_to project_progress_form_index_path
      return
    end

    # Load progress form data to edit
    session[:new_progress_form] = progress_form.json_data
    session[:progress_form_deadline] = progress_form.deadline

    @progress_form_json = session[:new_progress_form]
    @progress_form_deadline = progress_form.deadline
  end

  # AJAX Routes
  def add_question
    question = params[:question]

    session[:new_progress_form]['questions'] = [] if session[:new_progress_form]['questions'].nil?

    # Handle errors
    if session[:new_progress_form]['questions'].include?(question)
      @error = 'Cannot have duplicate questions.'

    elsif question.blank?
      @error = 'Question cannot be empty.'

    else
      session[:new_progress_form]['questions'] << params[:question]
    end

    @progress_form_json = session[:new_progress_form]
    @progress_form_deadline = session[:progress_form_deadline]

    return unless request.xhr?

    respond_to(&:js)
  end

  def delete_question
    # This won't throw an error if the index is invalid and an invalid index would mean the question isn't there,
    # so we can just re-render the partial anyways.
    session[:new_progress_form]['questions'].delete_at(params[:question_index])

    render partial: 'progress_form',
           locals:
        {
          progress_form: JSON.parse(session[:new_progress_form].to_json),
          release_date: session[:progress_form_deadline],
          progress_response: nil,
          group: 'None',
          facilitator: false,
          editing_form: true # Force editable because release date might not be set yet
        }
  end

  def change_title
    title = params[:title]

    taken_titles = get_progress_forms_for_project.map { |pf| pf.json_data['title'] }

    if taken_titles.include?(title)
      @error = 'There is already a progress form with this title.'

    elsif title.blank?
      @error = 'Title cannot be empty.'
    end

    if @error.nil?
      session[:new_progress_form]['title'] = title

      @progress_form_json = session[:new_progress_form]
      @progress_form_deadline = session[:progress_form_deadline]

    end

    return unless request.xhr?

    respond_to(&:js)
  end

  def save_form
    # To save the form there must be at least one question
    if session[:new_progress_form]['questions'].empty?
      return render json: {
        status: 'error',
        message: 'Must have at least one question!'
      }
    end

    # Session progress form deadline won't be set if we are creating new
    creating_new = session[:progress_form_deadline].nil? || session[:progress_form_deadline] == ''

    # Try find a pre-existing form to update
    unless creating_new
      milestone = get_progress_forms_for_project.select do |m|
        m.deadline.strftime('%Y-%m-%dT%H:%M') == session[:progress_form_deadline].strftime('%Y-%m-%dT%H:%M')
      end.first
    end

    # Update progress form, must be after get milestone incase 'primary key' changes
    session[:new_progress_form]['attendance'] = params[:attendance]

    # HTML date formatted like this YYYY-MM-DDT17:25
    formatted_deadline = params[:release_date].gsub('T', ' ')

    # Create or update milestone to represent the form
    if milestone.nil?
      milestone = Milestone.new(
        json_data: session[:new_progress_form],
        deadline: formatted_deadline,
        milestone_type: :team,
        course_project_id: session[:current_project_id]
      )
    else
      if creating_new
        return render json: {
          status: 'error',
          message: 'Cannot save progress form with duplicate release date.'
        }
      end

      # Update milestone data
      milestone.json_data = session[:new_progress_form]
      milestone.deadline = formatted_deadline
    end

    # For determining what milestone is a progress form.
    milestone.json_data['name'] = 'progress_form'

    # Handle save failure
    unless milestone.save
      return render json: {
        status: 'error',
        message: 'Failed to save progress form.'
      }
    end

    # Can't redirect_to from ajax so return path to redirect
    render json: {
      status: 'success',
      message: 'Saved form',
      redirect: project_progress_form_index_path
    }
  end

  def delete_form
    # Try find and delete a record if editing
    if params[:id]
      milestone = get_progress_forms_for_project.select { |m| m.id == params[:id].to_i }.first

      # If we don't find a milestone to delete, there is no error because its already 'deleted'
      milestone&.destroy
    end

    session[:new_progress_form] = {}

    redirect_to action: :index
  end

  def show_new
    return if params[:release_date] == ''

    # Update the current displayed form
    formatted_release_date = DateTime.parse(params[:release_date].gsub('T', ' '))

    @progress_form = get_progress_forms_for_project.select do |m|
      date_to_string(m.deadline) == date_to_string(formatted_release_date)
    end.first

    session[:progress_form_id] = @progress_form.id

    # Handle group not being specified
    if params[:group_name] == 'None'
      group = params[:group_name]
    else
      group = CourseProject.find(session[:current_project_id]).groups.find_by(name: params[:group_name])

      @progress_response = @progress_form.milestone_responses.select do |mr|
        mr.json_data['group_id'] == group.id
      end.first

    end

    # Return the html for the new progress form
    render partial: 'progress_form', locals:
      {
        progress_form_id: @progress_form.id,
        progress_form: @progress_form.json_data,
        release_date: @progress_form.deadline,
        progress_response: @progress_response.nil? ? nil : @progress_response.json_data,
        group:,
        facilitator: false,
        editing_form: false
      }
  end

  private

  def get_progress_forms_for_project
    # Helper for returning the correct milestones
    Milestone.select do |m|
      m.json_data['name'] == 'progress_form' &&
        m.course_project_id == session[:current_project_id]
    end
  end

  def date_to_string(date)
    date.strftime('%d/%m/%Y %H:%M')
  end
end
