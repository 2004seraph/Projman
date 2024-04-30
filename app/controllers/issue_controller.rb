class IssueController < ApplicationController
    authorize_resource class: false

    def index
        if params[:selected_project].nil?
            @selected_project = "All"
        else
            @selected_project = params[:selected_project]
        end

        if params[:selected_order].nil?
            @selected_order = "Created At"
        else
            @selected_order = params[:selected_order]
        end

        get_issues
        
        render 'index'
    end

    def update_selection
        @selected_project = params[:selected_project]
        @selected_order = params[:selected_order]

        get_issues(@selected_project, @selected_order)

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
            author: params[:author],
            reopened_by: "",
            updated: false
        }

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
        @issue = Event.find(params[:issue_id])

        @selected_project = params[:selected_project]
        @selected_order = params[:selected_order]

        json_data = {
            content: params[:response],
            author: params[:author],
            timestamp: Time.now
        }

        if current_user.is_staff?
            @issue_response = EventResponse.new(json_data: json_data, event_id: params[:issue_id], staff_id: current_user.staff.id)

            if @issue.json_data['reopened_by'] != current_user.staff.email
                @issue.json_data['reopened_by'] = ""
            end

            @issue.json_data['update'] = !@issue.json_data['update']

            @issue.update(json_data: @issue.json_data)
        else
            @issue_response = EventResponse.new(json_data: json_data, event_id: params[:issue_id], student_id: current_user.student.id)

            if @issue.json_data['reopened_by'] != current_user.student.username
                @issue.json_data['reopened_by'] = ""
            end
            
            @issue.json_data['update'] = !@issue.json_data['update']

            @issue.update(json_data: @issue.json_data)
        end

        @issue_response.save

        get_issues(@selected_project, @selected_order)

        if request.xhr?
            respond_to do |format|
                format.js
            end
        end
    end

    def update_status
        @issue = Event.find(params[:issue_id])

        @selected_project = params[:selected_project]
        @selected_order = params[:selected_order]

        if params[:status] == "closed"
            @issue.json_data['reopened_by'] = ""

            @issue.update(json_data: @issue.json_data, completed: true)
        else
            if current_user.is_staff?
                @issue.json_data['reopened_by'] = current_user.staff.email
            else
                @issue.json_data['reopened_by'] = current_user.student.username
            end

            @issue.update(json_data: @issue.json_data, completed: false)
        end

        get_issues(@selected_project, @selected_order)

        if request.xhr?
            respond_to do |format|
                format.js
            end
        end
    end

    private

    def get_issues(selected_project = 'All', selected_order = "Created At")
        @open_issues = []
        @resolved_issues = []

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

            if selected_project != "All"
                project = CourseProject.find_by(name: selected_project)

                @project_groups = Group.where(course_project_id: project.id)
            end

            if selected_order == "Created At"
                group_ids = @project_groups.map(&:id).uniq

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
                group_ids = @project_groups.map(&:id).uniq

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
                    group_id = group.id
                    group_ids = [group.id].flatten
                else
                    group_ids = []
                end
            end

            if !(group_ids.empty?)
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
