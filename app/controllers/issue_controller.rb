# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

# Controller for managing issue-related actions such as:
#   - Creating an issue
#   - Updating the selction of issues being shown
#   - Handling response to issues
#   - Updating the status of an issue
class IssueController < ApplicationController
  authorize_resource class: false

  def index
    @selected_project = if params[:selected_project].nil?
      "All"
    else
      params[:selected_project]
    end

    @selected_order = if params[:selected_order].nil?
      "Created At"
    else
      params[:selected_order]
    end

    get_issues

    render "index"
  end

  # Updates the current selection of issues.
  # @return [JavaScript Response] A javascript response which rerenders the
  #   page with the updated collection of issues in specified order.
  def update_selection
    @selected_project = params[:selected_project]
    @selected_order = params[:selected_order]

    get_issues(@selected_project, @selected_order)

    return unless request.xhr?

    respond_to(&:js)
  end

  # Creates a new issue.
  # @return [JavaScript Response] A javascript response which closes the modal
  #   and shows a success message if successful.
  def create
    json_data = {
      title:       params[:title],
      content:     params[:description],
      author:      params[:author],
      reopened_by: "",
      updated:     false
    }

    current_project_id = params[:project_id]
    group = current_user.student.groups.find_by(course_project_id: current_project_id)

    @issue = Event.new(completed: false, event_type: :issue, json_data:, group_id: group.id,
                       student_id: current_user.student.id)

    return unless @issue.save
    return unless request.xhr?

    respond_to(&:js)
  end

  # Handles the creation of an EventResponse to an issue.
  # @return [JavaScript Response] A javascript response which rerenders the
  #   issue box to upadate with new issue response and checks notification logic
  #   to see if notification icon needs to be removed.
  def issue_response
    @issue = Event.find(params[:issue_id])

    @selected_project = params[:selected_project]
    @selected_order = params[:selected_order]

    json_data = {
      content:   params[:response],
      author:    params[:author],
      timestamp: Time.zone.now
    }

    if current_user.is_staff?
      @issue_response = EventResponse.new(json_data:, event_id: params[:issue_id],
                                          staff_id: current_user.staff.id)

      @issue.json_data["reopened_by"] = "" if @issue.json_data["reopened_by"] != current_user.staff.email

    else
      @issue_response = EventResponse.new(json_data:, event_id: params[:issue_id],
                                          student_id: current_user.student.id)

      @issue.json_data["reopened_by"] = "" if @issue.json_data["reopened_by"] != current_user.student.username

    end
    @issue.json_data["update"] = !@issue.json_data["update"]
    @issue.update(json_data: @issue.json_data)

    @issue_response.save

    get_issues(@selected_project, @selected_order)

    return unless request.xhr?

    respond_to(&:js)
  end

  # Updates the issue's status to either open or resolved.
  # @return [JavaScript Response] A javascript response which rerenders the
  #   page with the issue moved to the corresponding section of with open
  #   issues or resolved issues. Also checks notification logic
  #   to see if notification icon needs to be removed.
  def update_status
    @issue = Event.find(params[:issue_id])

    @selected_project = params[:selected_project]
    @selected_order = params[:selected_order]

    if params[:status] == "closed"
      @issue.json_data["reopened_by"] = ""

      @issue.update(json_data: @issue.json_data, completed: true)
    else
      @issue.json_data["reopened_by"] = if current_user.is_staff?
        current_user.staff.email
      else
        current_user.student.username
      end

      @issue.update(json_data: @issue.json_data, completed: false)
    end

    get_issues(@selected_project, @selected_order)

    return unless request.xhr?

    respond_to(&:js)
  end

  private
    # Updates the instance variables @open_issues and @resolved_issues based
    #   on parameters from view to update the issues rendered in the view and
    #   their order.
    # @param [String] selected_project The current selected project in the view.
    # @param [String] selected_order The current selected order in the view.
    def get_issues(selected_project = "All", selected_order = "Created At")
      @open_issues = []
      @resolved_issues = []

      if current_user.is_admin?
        @user_projects = CourseProject.all

        if selected_order == "Created At"
          group_ids = Group.all.map(&:id).uniq

          @open_issues = Event.joins(:group)
                              .where(groups: { id: group_ids })
                              .where(event_type: :issue)
                              .where(completed: false)
                              .order(created_at: :asc)

          @resolved_issues = Event.joins(:group)
                                  .where(groups: { id: group_ids })
                                  .where(event_type: :issue)
                                  .where(completed: true)
                                  .order(created_at: :asc)

        else
          group_ids = Group.all.map(&:id).uniq

          @open_issues = Event.joins(:group)
                              .where(groups: { id: group_ids })
                              .where(event_type: :issue)
                              .where(completed: false)
                              .order(updated_at: :desc)

          @resolved_issues = Event.joins(:group)
                                  .where(groups: { id: group_ids })
                                  .where(event_type: :issue)
                                  .where(completed: true)
                                  .order(updated_at: :desc)
        end

      elsif current_user.is_staff?
        @user_modules = current_user.staff.course_modules

        @user_projects = []
        @user_modules.each do |user_module|
          @user_projects += user_module.course_projects
        end

        @project_groups = []
        @user_projects.each do |user_project|
          @project_groups += user_project.groups
        end

        if selected_project != "All"
          project = CourseProject.find_by(name: selected_project)

          @project_groups = Group.where(course_project_id: project.id)
        end

        group_ids = @project_groups.map(&:id).uniq
        if selected_order == "Created At"

          @open_issues = Event.joins(:group)
                              .where(groups: { id: group_ids })
                              .where(event_type: :issue)
                              .where(completed: false)
                              .order(created_at: :asc)

          @resolved_issues = Event.joins(:group)
                                  .where(groups: { id: group_ids })
                                  .where(event_type: :issue)
                                  .where(completed: true)
                                  .order(created_at: :asc)
        else

          @open_issues = Event.joins(:group)
                              .where(groups: { id: group_ids })
                              .where(event_type: :issue)
                              .where(completed: false)
                              .order(updated_at: :desc)
          @resolved_issues = Event.joins(:group)
                                  .where(groups: { id: group_ids })
                                  .where(event_type: :issue)
                                  .where(completed: true)
                                  .order(updated_at: :desc)
        end
      else
        @user_projects = current_user.student.course_projects
        @user_groups = current_user.student.groups
        group_ids = @user_groups.map(&:id).uniq

        if selected_project != "All"
          project = CourseProject.find_by(name: selected_project)

          group = current_user.student.groups.find_by(course_project_id: project.id)

          if !group.nil?
            group.id
            group_ids = [group.id].flatten
          else
            group_ids = []
          end
        end

        unless group_ids.empty?
          if selected_order == "Created At"
            @open_issues = Event.joins(:group)
                                .where(groups: { id: group_ids })
                                .where(event_type: :issue)
                                .where(completed: false)
                                .where(student_id: current_user.student.id)
                                .order(created_at: :asc)

            @resolved_issues = Event.joins(:group)
                                    .where(groups: { id: group_ids })
                                    .where(event_type: :issue)
                                    .where(completed: true)
                                    .where(student_id: current_user.student.id)
                                    .order(created_at: :asc)
          else
            @open_issues = Event.joins(:group)
                                .where(groups: { id: group_ids })
                                .where(event_type: :issue)
                                .where(completed: false)
                                .where(student_id: current_user.student.id)
                                .order(updated_at: :desc)

            @resolved_issues = Event.joins(:group)
                                    .where(groups: { id: group_ids })
                                    .where(event_type: :issue)
                                    .where(completed: true)
                                    .where(student_id: current_user.student.id)
                                    .order(updated_at: :desc)
          end
        end
      end
    end

    def issue_params
      params.require(:issue).permit(:title, :content, :author, :project_id, :issue_id, :response, :description)
    end
end
