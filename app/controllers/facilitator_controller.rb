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
            # I am assuming here that a facilitator will only be asked to facilitate for teams in projects
            # that they're already a facilitator for.

            # TODO: Need to test
            facilitator_project_ids = get_assigned_facilitators.map{|x| x.course_project_id}
            @assigned_facilitators = AssignedFacilitator.where(course_project_id: facilitator_project_ids)
        end
        
        unless params[:projects_filter] == "All" || params[:projects_filter].empty?
            target_project_id = CourseProject.find_by(name: params[:projects_filter]).id
            @assigned_facilitators = @assigned_facilitators.where(course_project_id: target_project_id)
        end

        set_assigned_projects
        render partial: "teams-list-card"
    end

    def progress_form
        authorize! :read, :facilitator

        set_current_group
                
        @progress_form = get_progress_forms_for_group.select{|m|
            m.json_data["release_date"] == params[:release_date]
        }.first
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
            @progress_response = MilestoneResponse.new(
                json_data: {
                    group_id: @current_group.id, 
                    attendance: [],
                    question_responses: [],
                    facilitator_repr: get_facilitator_repr(
                        get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first
                    )
                },
                milestone_id: @progress_form.id
            )

            # Handle save failure
            unless @progress_response.save
                puts "[ERROR] TODO: Must handle progress response save failure."
            end
        end
    end

    def marking_show
        authorize! :read, :facilitator
    end

    def team
        # Display team/group area
        team = Group.find(params[:id])
        authorize! :read, team

        set_current_group
        
        # Get progress forms and sort by release date
        @progress_forms = get_progress_forms_for_group.sort_by{ 
            |m| Date.strptime(m.json_data["release_date"], "%Y-%m-%d") 
        }

        # Split into sections
        @progress_forms_submitted = @progress_forms.select{
            |pf| pf.milestone_responses.select{|mr| mr.json_data["group_id"] == @current_group.id}.length > 0
        }
        
        @progress_forms_todo = @progress_forms - @progress_forms_submitted
    end

    def set_assigned_projects
        @assigned_projects = get_assigned_facilitators.map{|x| CourseProject.find(x.course_project_id)}
    end

    def update_progress_form_response
        @current_group = Group.find(session[:team_id])

        # Update milestone response for progress form
        @progress_form = Milestone.find(session[:progress_form_id])
        @progress_response = @progress_form.milestone_responses.select{
            |mr| mr.json_data["group_id"] == @current_group.id
        }.first

        if @progress_response.nil?
            # TODO: Handle error here
            puts "[ERROR] Progress response was nil when tried to update, should handle this properly."
        else
            @progress_response.json_data[:attendance] = params[:attendance]
            @progress_response.json_data[:question_responses] = params[:question_responses]

            # TODO: Show facilitator name and email, gotta figure out getting staff name.
            @progress_response.json_data[:facilitator_repr] = get_facilitator_repr(
                get_assigned_facilitators.where(course_project_id: @current_group.course_project_id).first
            )

        end

        unless @progress_response.save
            # TODO: Handle error
            puts "[ERROR] Progress response failed to save, should handle this properly."
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

        def set_current_group
            # TODO: Need to switch everything to group instead of team to match models
            # TODO: Stop the symbols and just use session as this is used alot maybe? Gets very confusing
            session[:team_id] = params[:team_id]
            @current_group = Group.find(params[:team_id])
            @current_group_facilitator_repr = get_facilitator_repr(@current_group.assigned_facilitator)
        end

        def get_facilitator_repr(facilitator)
            # TODO: Use User.rb model to get staff name... but can't figure this out?

            # TODO: Test student works
            if facilitator.student_id
                student = Student.find_by(id: facilitator.student_id)
                return "#{student.forename} #{student.surname}"

            elsif facilitator.staff_id
                return Staff.find_by(id: facilitator.staff_id).email
            end
        end

        def get_progress_forms_for_group
            Milestone.select{
                |m| m.json_data["name"] == "progress_form" && 
                Date.parse(m.json_data["release_date"]) <= Date.today && # Only get released forms 
                m.course_project_id == @current_group.course_project_id
            }
        end
end