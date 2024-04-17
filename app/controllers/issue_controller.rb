class IssueController < ApplicationController
    # load_and_authorize_resource


    def index
        get_all_issues

        @view_as_manager = false
        if @view_as_manager
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def update_selection
        get_all_issues

        if !(params[:selected_project] == 'All' || params[:selected_project].nil?)
            project_selected = params[:selected_project]
            project = CourseProject.find_by(name: project_selected)


            group = @user_groups.find_by(course_projects_id: project.id)

            @open_issues = Event.where(event_type: Event.event_types[:issue], completed: false, group_id: group.id)
            @resolved_issues = Event.where(event_type: Event.event_types[:issue], completed: true, group_id: group.id)
        end

        render partial: 'issues-section'
    end

    def create
        json_data = {
            title: params['title'],
            content: params['content'],
            author: params['author']
        }.to_json

        current_project_id = params['project_id']
        group = current_user.student.groups.find_by(course_projects_id: current_project_id)

        @issue = Event.new(completed: false, event_type: :issue, json_data: json_data, group_id: group.id)

        if @issue.save
            render json: { success: true }
        else
            render json: { success: false, errors: @issue.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def get_all_issues
        if current_user.is_student?
            @open_issues = []
            @resolved_issues = []

            @user_projects = []

            @user_groups = current_user.student.groups
            @user_groups.each do |user_group|
                current_issue = Event.where(event_type: Event.event_types[:issue], completed: false, group_id: user_group.id)
                if !current_issue.nil?
                    @open_issues += current_issue
                end

                current_issue = Event.where(event_type: Event.event_types[:issue], completed: true, group_id: user_group.id)
                if !current_issue.nil?
                    @resolved_issues += current_issue
                end

                @user_projects += CourseProject.where(id: user_group.course_project_id)
            end
        else
            @open_issues = Event.where(event_type: Event.event_types[:issue], completed: false)
            @resolved_issues = Event.where(event_type: Event.event_types[:issue], completed: true)
        end
    end

    def issue_params
        params.require(:issue).permit(:title, :content, :author, :project_id)
    end
end
