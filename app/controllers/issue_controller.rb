class IssueController < ApplicationController
    authorize_resource class: false, except: :update_selection
    

    def index
        get_all_issues

        @view_as_manager = true
        if @view_as_manager            
            render 'index_module_leader'
        else
            render 'index_student'
        end
    end

    def update_selection
        authorize! :read, :issue

        get_all_issues

        if current_user.is_student?
            if !(params[:selected_project] == 'All' || params[:selected_project].nil?)   
                project_selected = params[:selected_project]
                project = CourseProject.find_by(name: project_selected)

                group = @user_groups.find_by(course_project_id: project.id)

                @open_issues = Event.where(event_type: :issue, completed: false, group_id: group.id)
                @resolved_issues = Event.where(event_type: :issue, completed: true, group_id: group.id)
            end
        else
            if !(params[:selected_project] == 'All' || params[:selected_project].nil?)   
                project_selected = params[:selected_project]
                project = CourseProject.find_by(name: project_selected)

                @project_groups = Group.where(course_project_id: project.id)

                @open_issues = []
                @resolved_issues = []
                @project_groups.each do |project_group|
                    @open_issues += Event.where(event_type: :issue, completed: false, group_id: project_group.id)
                    @resolved_issues += Event.where(event_type: :issue, completed: true, group_id: project_group.id)
                end
            end
        end

        render partial: 'issues-section'
    end

    def create
        json_data = { 
            title: params[:title],
            content: params[:description],
            author: params[:author]
        }.to_json

        current_project_id = params[:project_id]
        group = current_user.student.groups.find_by(course_project_id: current_project_id)

        @issue = Event.new(completed: false, event_type: :issue, json_data: json_data, group_id: group.id)

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
        @issue = Event.find_by(id: params[:issue_id])

        @issue.add_response(params[:author], params[:response])

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

    def get_all_issues
        @open_issues = []
        @resolved_issues = []
        @user_projects = []

        # if current_user.isStudent?
        if current_user.is_student?
            @user_groups = current_user.student.groups
            @user_groups.each do |user_group|
                current_issue = Event.where(event_type: :issue, completed: false, group_id: user_group.id)
                if !current_issue.nil?
                    @open_issues += current_issue
                end
                
                current_issue = Event.where(event_type: :issue, completed: true, group_id: user_group.id)
                if !current_issue.nil?    
                    @resolved_issues += current_issue
                end

                @user_projects += CourseProject.where(id: user_group.course_project_id)
            end
        else
            @user_modules = CourseModule.where(staff_id: current_user.staff.id)
            @user_modules.each do |user_module|
                @user_projects += CourseProject.where(course_module_id: user_module.id)
            end

            @project_groups = []
            @user_projects.each do |user_project|
                @project_groups += Group.where(course_project_id: user_project.id)
            end

            @project_groups.each do |project_group|
                @open_issues += Event.where(event_type: :issue, completed: false, group_id: project_group.id)
                @resolved_issues += Event.where(event_type: :issue, completed: true, group_id: project_group.id)
            end

            
        end
    end

    def issue_params
        params.require(:issue).permit(:title, :content, :author, :project_id, :issue_id, :response, :description)
    end
end
