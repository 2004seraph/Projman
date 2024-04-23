class IssueController < ApplicationController
    authorize_resource class: false

    def index
        @selected_project = "All"

        get_issues

        if current_user.is_staff?
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def update_selection

        @selected_project = params[:selected_project]

        get_issues(@selected_project)

        # if !(params[:selected_project] == 'All' || params[:selected_project].nil?)
        #     @open_issues = []
        #     @resolved_issues = []

        #     project_selected = params[:selected_project]
        #     project = CourseProject.find_by(name: project_selected)

        #     if current_user.is_staff?
        #         @project_groups = Group.where(course_project_id: project.id)

        #         @project_groups.each do |project_group|
        #             @open_issues += project_group.events.where(event_type: :issue, completed: false)
        #             @resolved_issues += project_group.events.where(event_type: :issue, completed: true)
        #         end
        #     else
        #         group = @user_groups.find_by(course_project_id: project.id)

        #         if !(group.nil?)
        #             @open_issues += current_user.student.events.where(event_type: :issue, completed: false, group_id: group.id)
        #             @resolved_issues += current_user.student.events.where(event_type: :issue, completed: true, group_id: group.id)
        #         end
        #     end
        # end

        # render partial: 'issues-section'
        if request.xhr?
            respond_to do |format|
                format.js
            end
        end
    end

    def create
        json_data = {
            title: params[:title],
            content: params[:description],
            author: params[:author]
        }.to_json

        current_project_id = params[:project_id]
        group = current_user.student.groups.find_by(course_project_id: current_project_id)

        @issue = Event.new(completed: false, event_type: :issue, json_data: json_data, group_id: group.id, student_id: current_user.student.id)

        if @issue.save
            if request.xhr?
                respond_to do |format|
                    format.js
                end
            end
        else

        end
    end

    def issue_response
        json_data = {
            content: params[:response],
            author: params[:author],
            timestamp: Time.now
        }.to_json

        if current_user.is_staff?
            @issue_response = EventResponse.new(json_data: json_data, event_id: params[:issue_id], staff_id: current_user.staff.id)
        else
            @issue_response = EventResponse.new(json_data: json_data, event_id: params[:issue_id], student_id: current_user.student.id)
        end

        @issue_response.save

        if request.xhr?
            respond_to do |format|
                format.js
            end
        end
    end

    def update_status
        @issue = Event.find(params[:issue_id])

        if params[:status] == "closed"
            @issue.update(completed: true)
        else
            @issue.update(completed: false)
        end

        get_issues

        if request.xhr?
            respond_to do |format|
                format.js
            end
        end
    end

    def issue_box
        @issue = Event.find(params[:id])
        respond_to do |format|
            format.html { render partial: 'issue-box', locals: { issue: @issue } }
        end
    end

    private

    def get_issues(selected_project = 'All')
        @open_issues = []
        @resolved_issues = []

        # if current_user.isStudent?
        if current_user.is_staff?
            @user_modules = current_user.staff.course_modules

            @user_projects = []
            @user_modules.each do |user_module|
                @user_projects += user_module.course_projects
            end

            @project_groups = []
            @user_projects.each do |user_project|
                @project_groups += user_project.groups
            end

            if selected_project == "All"
                @project_groups.each do |project_group|
                    @open_issues += project_group.events.where(event_type: :issue, completed: false)
                    @resolved_issues += project_group.events.where(event_type: :issue, completed: true)
                end
            else
                project = CourseProject.find_by(name: selected_project)

                @project_groups = Group.where(course_project_id: project.id)

                @project_groups.each do |project_group|
                    @open_issues += project_group.events.where(event_type: :issue, completed: false)
                    @resolved_issues += project_group.events.where(event_type: :issue, completed: true)
                end
            end
        else
            @user_projects = current_user.student.course_projects
            @user_groups = current_user.student.groups

            if selected_project == "All"
                @open_issues += current_user.student.events.where(event_type: :issue, completed: false)
                @resolved_issues += current_user.student.events.where(event_type: :issue, completed: true)
            else
                project = CourseProject.find_by(name: selected_project)

                group = @user_groups.find_by(course_project_id: project.id)

                if !(group.nil?)
                    @open_issues += current_user.student.events.where(event_type: :issue, completed: false, group_id: group.id)
                    @resolved_issues += current_user.student.events.where(event_type: :issue, completed: true, group_id: group.id)
                end
            end
        end
    end

    def issue_params
        params.require(:issue).permit(:title, :content, :author, :project_id, :issue_id, :response, :description)
    end
end
