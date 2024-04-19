class FacilitatorController < ApplicationController
    authorize_resource class: false, except: [:update_teams_list, :marking_show, :team, :progress_form]

    # GET /facilitators
    def index
        @assigned_facilitators = get_assigned_facilitators
        set_assigned_projects
    end

    def update_teams_list
        authorize! :read, :facilitator
        # Apply filters to the shown teams
        if params[:assigned_only]
            @assigned_facilitators = get_assigned_facilitators

        else
            # NOTE: I am assuming here that a facilitator will only be asked to facilitate for teams in projects
            #       that they're already a facilitator for

            # TODO: Need to test
            facilitator_project_ids = get_assigned_facilitators.map{|x| x.course_project_id}
            @assigned_facilitators = AssignedFacilitator.where(course_project_id: facilitator_project_ids)
        end

        unless params[:projects_filter] == "All" || params[:projects_filter].empty?
            target_project_id = CourseProject.find_by(name: params[:projects_filter]).id
            @assigned_facilitators = @assigned_facilitators.select{|x| x.course_project_id == target_project_id}
        end

        set_assigned_projects
        render partial: "teams-list-card"
    end


    def progress_form
        authorize! :read, :facilitator

        set_group
                
        @progress_form = Milestone.select{|m| m.course_project_id == @current_group.course_project_id && m.json_data["release_date"] == params[:release_date]}.first
        session[:progress_form_id] = @progress_form.id

        # Create initial milestone response if we don't have one
        
        # Try find a milestone response
        @progress_response = @progress_form.milestone_responses.select{
            |mr| mr.json_data["group_id"] == @current_group.id
        }.first

        if @progress_response.nil?
            # TODO: Set these?
            #  staff_id     :bigint
            #  student_id   :bigint
            # TODO: Fill in
            @progress_response = MilestoneResponse.new(
                json_data: {
                    group_id: @current_group.id, 
                    attendance: [],
                    question_responses: [],
                    facilitator_repr: get_facilitator_repr(get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first)
                },
                milestone_id: @progress_form.id
            )

            # Handle save failure
            unless @progress_response.save
                puts "\n! ! ! FAILED TO SAVE\n"
            end
        end
    end

    def marking_show
        authorize! :read, :facilitator
    end

    def team
        team = Group.find(params[:id])
        authorize! :read, team

        set_group

        @progress_forms = Milestone.where(course_project_id: @current_group.course_project_id).sort_by{ |m| Date.strptime(m.json_data["release_date"], "%Y-%m-%d") }
        @progress_forms_submitted = @progress_forms.select{|pf| pf.milestone_responses.select{|mr| mr.json_data["group_id"] == @current_group.id}.length > 0}
        @progress_forms_todo = @progress_forms - @progress_forms_submitted

    end

    def set_assigned_projects
        @assigned_projects = get_assigned_facilitators.map{|x| CourseProject.find(x.course_project_id)}
    end

    def update_progress_form_response
        # TODO: SHOULD SAVE LAST UPDATED BY ID...

        @current_group = Group.find(session[:team_id])

        # Update milestone response for progress form
        @progress_form = Milestone.find(session[:progress_form_id])
        @progress_response = @progress_form.milestone_responses.select{
            |mr| mr.json_data["group_id"] == @current_group.id
        }.first

        if @progress_response.nil?
            # TODO: Handle error here
            puts "THIS SHOULD NOT HAPPEN BUT SHOULD PROBABLY HANDLE"
        else
            @progress_response.json_data[:attendance] = params[:attendance]
            @progress_response.json_data[:question_responses] = params[:question_responses]

            # TODO: Show name and email, gotta figure out getting staff name.
            @progress_response.json_data[:facilitator_repr] = get_facilitator_repr(get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first)
        end

        unless @progress_response.save
            puts "FAILED TO UPDATE MILESTONE RESPONSE, HANDLE"
            return render json: { status: "error", message: "Failed to save milestone when save_form." }
        end

        # TODO: Scuffed but works, should make better later on.
        render json: { status: "success", redirect: facilitator_team_path(team_id: session[:team_id]) }
        
    end

    private

    def get_assigned_facilitators
        # Returns the entries of AssignedFacilitator for the logged in user
        if current_user.is_staff?
            return AssignedFacilitator.where(staff: current_user.staff)
        elsif current_user.is_student?
            return AssignedFacilitator.where(student: current_user.student)
        end
    end

        def set_group
            # TODO: Need to switch everything to group instead of team to match models
            # TODO: Stop the symbols and just use session as this is used alot ?
            session[:team_id] = params[:team_id]
            @current_group = Group.find(params[:team_id])
            @current_group_facilitator_repr = get_facilitator_repr(@current_group.assigned_facilitator)
        end

        def get_facilitator_repr(facilitator)
            # NOTE: There isn't a name currently for staff members I beleive,
            # TODO: Use User.rb model?

        # TODO: Test student
        if facilitator.student_id
            student = Student.find(facilitator.student_id)
            return "#{student.forename} #{student.surname}"
        elsif facilitator.staff_id
            return Staff.find(facilitator.staff_id).email
        end
        # TODO: Handle better?
    end
end