class FacilitatorController < ApplicationController
    before_action :set_group, only: %i[ team ]

    # GET /facilitators 
    def index
        @assigned_facilitators = get_assigned_facilitators
    end

    def update_teams_list
        # Apply filters to the shown teams
        if params[:assigned_only]
            @assigned_facilitators = get_assigned_facilitators

        else
            # NOTE: I am assuming here that a facilitator will only be asked to facilitate for teams in projects
            #       that they're already a facilitator for

            # TODO: Test
            facilitator_project_ids = get_assigned_facilitators.map{|x| x.course_project_id}   
            @assigned_facilitators = AssignedFacilitator.where(course_project_id: facilitator_project_ids)
        end
        
        render partial: "teams-list-card"
    end

    # GET /facilitators/marking/{module}
    def progress_form
    end

    def team
    end

    private
        def get_assigned_facilitators
            # Returns the entries of AssignedFacilitator for the logged in user
            if Staff.exists?(id: @user.id)
                return AssignedFacilitator.where(staff_id: @user.id)

            elsif Student.exists?(id: @user.id)
                return AssignedFacilitator.where(student_id: @user.id)            
            end
        end

        def set_group
            # TODO: Need to switch everything to group instead of team to match models
            @current_group = Group.find(params[:team_id])
            @current_group_facilitator_repr = get_current_group_facilitator_repr
        end
        
        def get_current_group_facilitator_repr
            # NOTE: There isn't a name currently for staff members I beleive
            facilitator = @current_group.assigned_facilitator
            
            # TODO: Test student
            if facilitator.student_id
                student = Student.find_by(id: facilitator.student_id)
                return "#{student.forename} #{student.surname}"

            elsif facilitator.staff_id
                return Staff.find_by(id: facilitator.staff_id).email
            end
        end

        
end