class FacilitatorController < ApplicationController
    #authorize_resource class: false, except: [:update_teams_list, :marking_show, :team, :progress_form]
    authorize_resource :milestone_response

    # GET /facilitators
    def index
        @assigned_facilitators = get_assigned_facilitators
        set_assigned_projects

        
        # TODO: For now, just displaying all sections of all mark schemes
        @mark_schemes = Milestone.select{|m| m.system_type == "marking_deadline"}

    end

    def update_teams_list
        authorize! :read, :facilitator

        # Apply filters to the shown teams
        if params[:assigned_only]
            @assigned_facilitators = get_assigned_facilitators

        else
            # I am assuming here that a facilitator will only be asked to facilitate for teams in projects
            # that they're already a facilitator for.
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
        get_progress_forms_for_group.each do |d|
            puts d.deadline.strftime("%d/%m/%Y %H:%M") 
        end

        puts params[:release_date]
        @progress_form = get_progress_forms_for_group.select{|m|
            m.deadline.strftime("%d/%m/%Y %H:%M") == params[:release_date]
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

        mark_scheme = Milestone.find(params[:milestone_id].to_i)
        
        @section = mark_scheme.json_data["sections"][params[:section_index].to_i]
        @mark_scheme_project = CourseProject.find(mark_scheme.course_project_id) 

        session[:mark_scheme_id] = mark_scheme.id
        session[:mark_scheme_section_index] = params[:section_index].to_i

        @assigned_teams = @section["facilitators"][current_user.email].map{|id| Group.find(id)}.sort_by(&:name)
        
        @assigned_teams_ids = @assigned_teams.flat_map(&:id)

        # Load marking responses for teams
        @team_marks = mark_scheme.milestone_responses.select{
            |mr| @assigned_teams_ids.include?(mr.json_data["group_id"])
        }
    end

    def team
        # Display team/group area
        set_current_group
        authorize! :read, :facilitator

        # Get progress forms and sort by release date
        @progress_forms = get_progress_forms_for_group.sort_by{ 
            |m| m.deadline 
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
        render json: { status: "success", redirect: facilitators_path(team_id: session[:team_id]) } 
    end

    def update_marking
        marking = params[:marking]
        
        mark_scheme = Milestone.find(session[:mark_scheme_id])
        section = mark_scheme.json_data["sections"][session[:mark_scheme_section_index]]
        
        group_ids = section["facilitators"][current_user.email]

        success = true
        group_ids.each do |group_id|
            group = Group.find(group_id)
            
            marks_given = marking[group_id.to_s][0]
            reason = marking[group_id.to_s][1]

            # Look for pre-existing marking for the group
            response = mark_scheme.milestone_responses.select{|ms| ms.json_data["group_id"] == group.id}.first

            if response.nil?
                response = MilestoneResponse.new(
                    json_data: {
                        "sections": {
                            section["title"] => {
                                "marks_given" => marks_given,
                                "reason" => reason
                            }
                        },
                        "group_id": group.id
                    },
                    milestone_id: mark_scheme.id
                )
            else
                # Using title as primary key for section as sections can be deleted.
                if response.json_data["sections"][section["title"]].nil?
                    response.json_data["sections"][section["title"]] = {}
                end

                response.json_data["sections"][section["title"]]["marks_given"] = marks_given
                response.json_data["sections"][section["title"]]["reason"] = reason
            end

            if !response.save
                success = false
            end
        end

        if success
            return render json: {status: "success", redirect: facilitators_path}
        end

        render json: {status: "error", message: "Failed to save marking."}
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
            #Milestone.select{
            #    |m| m.system_type == "progress_form_deadline" && 
            #    Date.parse(m.json_data["release_date"]) <= Date.today && # Only get released forms 
            #    m.course_project_id == @current_group.course_project_id
            #}

            Milestone.select{
                |m| m.json_data["name"] == "progress_form" && 
                m.deadline <= DateTime.current && # Only get released forms 
                m.course_project_id == @current_group.course_project_id
            }
        end
end