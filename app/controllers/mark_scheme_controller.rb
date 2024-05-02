class MarkSchemeController < ApplicationController
  load_and_authorize_resource :milestone_response

  def index
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    authorize! :read, @current_project

    milestone = get_mark_scheme
    unless milestone.nil?
        @mark_scheme = milestone.json_data
    end
  end

  def new
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    mark_scheme = get_mark_scheme
    if mark_scheme.nil?
        session[:mark_scheme] = hash_to_json({ 
            "sections": [],
        })
    else    
        redirect_to edit_project_mark_scheme_path(id: mark_scheme.id)
    end
  end

  def edit
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    mark_scheme = get_mark_scheme
    if mark_scheme.nil?
        redirect_to new_project_mark_scheme_path
    else
        session[:mark_scheme] = mark_scheme.json_data
    end
  end

    def add_section
        # Facilitators would be a list of the facilitator emails and then the marking is split evenly. 
        section = {title: params[:section_title], description: "", max_marks: 0}
        session[:mark_scheme]["sections"] << hash_to_json(section)
        
        # Render a new section, if i re-rendered the whole mark scheme, it would reset the textareas and inputs.
        render partial: "section", locals: {
            section_index: session[:mark_scheme]["sections"].length - 1, 
            section_title: params[:section_title], 
            section_description: "",
            max_marks: 0}
    end

    def delete_section
        # Find the section with the matching title and remove it
        target_index = -1
        session[:mark_scheme]["sections"].each_with_index do |section, i|
            if params["section_title"] == section["title"]
                target_index = i
                next
            end
        end

        if target_index == -1
            return render json: {status: "error", message: "Failed to find matching section to remove."}
        end

        session[:mark_scheme]["sections"].delete_at(target_index)

        return render json: {status: "success"}
    end

  def save
    # Everything is taken from the inputs, the session is only used for rendering stuff.
    if params[:sections].length < 1 
        return render json: { 
            status: "error", 
            message: "Must have at least one section!" 
        }
    end

    data_valid = true

    # Ensure max marks are valid or return error
    params[:sections].each do |section|
        if section["max_marks"] !~ /\A\d+\z/
            return render json: { 
                status: "error", 
                message: "Max marks must be a positive whole number." 
            }
        end
    end

    milestone = get_mark_scheme

    # Update section data without resetting assigned facilitators
    params[:sections].each_with_index do |section, i|
        session[:mark_scheme]["sections"][i]["title"] = section["title"]
        session[:mark_scheme]["sections"][i]["description"] = section["description"]
        session[:mark_scheme]["sections"][i]["max_marks"] = section["max_marks"]
    end

    # Create or update milestone to represent the form
    if milestone.nil?
        milestone = Milestone.new(
            json_data: session[:mark_scheme],
            deadline: Date.current.strftime("%Y-%m-%d"), # Deadline isn't used here
            milestone_type: :team, # Marks will be given per team
            course_project_id: params[:project_id],
            system_type: :marking_deadline
        )
    else
        milestone.json_data = session[:mark_scheme]
        milestone.deadline = Date.current.strftime("%Y-%m-%d") # Deadline isn't used here
    end

    # Handle save failure
    unless milestone.save
        return render json: { 
            status: "error", 
            message: "Failed to save milestone when save mark scheme." 
        }
    end

    # Can't redirect from ajax here, so must do it from js
    render json: { 
        status: 'success', 
        message: 'Saved mark scheme', 
        redirect: project_mark_scheme_index_path
    }
  end

    def search_facilitators
        # Return all possible facilitators for the current project, given the search criteria.
        query = params[:query]

        if query.nil? then query = "" end

        @results = AssignedFacilitator.select{|f| f.course_project_id == session[:current_project_id] && 
            f.get_email.include?(query.downcase)}

        render json: @results.map{|r| r.get_email}
    end
  
    def add_to_facilitators_selection
        # Section index is not a param in the confirm ajax, so set it here to use there.
        session[:current_section_index] = params[:section_index]
        
        # Handle invalid email by just not adding to selected
        if AssignedFacilitator.select{|f| f.course_project_id == session[:current_project_id] && 
            f.get_email == params[:section_facilitator_email]}.first.nil?
            return
        end 

        @facilitator_email = params[:section_facilitator_email]

        if @facilitator_email.present?
            if session[:facilitator_selection].nil?
                session[:facilitator_selection] = [@facilitator_email]
            else
                session[:facilitator_selection] << @facilitator_email
            end
        end

        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def add_facilitators_selection
        section_index = session[:current_section_index].to_i

        milestone = get_mark_scheme
        mark_scheme = milestone.json_data

        # Initialise facilitators if necessary
        if mark_scheme["sections"][section_index]["facilitators"].nil?
            mark_scheme["sections"][section_index]["facilitators"] = {}
        end
        
        # Populate new facilitator emails into mark scheme milestone json data
        session[:facilitator_selection].each do |facilitator|
            unless mark_scheme["sections"][section_index]["facilitators"].include?(facilitator)
                mark_scheme["sections"][section_index]["facilitators"][facilitator] = []
            end
        end

        # Update the mark scheme
        milestone.json_data = mark_scheme
        unless milestone.save
            flash.alert = "Failed to assign facilitators to mark scheme."
        end

        # Re-render the view for assessors
        @mark_scheme = milestone.json_data

        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def remove_from_facilitator_selection
        @facilitator_email = params[:item_text].strip
        session[:facilitator_selection].delete(@facilitator_email)
    end

    def clear_facilitators_selection
        # Reset facilitator selection, only called when modal is first opened
        session[:facilitator_selection] = []
    end

    def remove_facilitator_from_section
        mark_scheme = get_mark_scheme
        mark_scheme.json_data["sections"][params[:section_index]]["facilitators"].delete(params[:email])
        
        unless mark_scheme.save
            flash.alert = "Failed to unassign facilitator from section."
        end
        
        render partial: "section_facilitators", locals: {mark_scheme: mark_scheme.json_data}
    end

    def get_assignable_teams
        # Return the remaining teams available to be assigned to a facilitator for the given section
        # Also contains teams already assigned to the facilitator
        
        groups = CourseProject.find(session[:current_project_id]).groups

        mark_scheme = get_mark_scheme

        section = mark_scheme.json_data["sections"][params[:section_index]]

        # Save params for submit modal
        session[:current_section_index] = params[:section_index]
        session[:current_facilitator_email] = params[:email]

        groups_to_show = {}
        groups.each do |group|
            groups_to_show[group.name] = {id: group.id, already_assigned: false}
        end
        
        section["facilitators"].each do |facilitator, team_ids|
            team_ids.each do |team_id|
                team = Group.find(team_id)
                if facilitator == params[:email] 
                    groups_to_show[team.name][:already_assigned] = true
                else
                    groups_to_show.delete(team.name)
                end
            end
        end
        
        render json: {groups_to_show: groups_to_show.values}
    end

    def assign_teams
        # Actually assign the selected teams from the modal to the chosen facilitator
        section_index = session[:current_section_index].to_i

        milestone = get_mark_scheme 
        mark_scheme = milestone.json_data

        # Get all the team ids that are taken, so we don't assign twice, incase someone inspects element.
        taken_teams = mark_scheme["sections"][section_index]["facilitators"].select{
            |email, _| email != session[:current_facilitator_email]
        }.values.flatten
        
        new_teams = params[:team_ids] - taken_teams
        mark_scheme["sections"][section_index]["facilitators"][session[:current_facilitator_email]] = new_teams

        milestone.json_data = mark_scheme

        unless milestone.save
            flash.alert = "Failed to assign teams to facilitator."
        end
        
        # Re-render the section to update table row
        render partial: "section_facilitators", locals: {mark_scheme: milestone.json_data}
    end

    def auto_assign_teams
        # Auto assign teams to all the chosen assessors for a section
        section_index = params[:section_index].to_i

        milestone = get_mark_scheme
        mark_scheme = milestone.json_data

        assessors = mark_scheme["sections"][section_index]["facilitators"]
        
        if assessors.nil? || assessors.empty?
            return render partial: "section_facilitators", locals: {mark_scheme: milestone.json_data}
        end
        
        # Split the teams between the assessors evenly
        group_ids = CourseProject.find(session[:current_project_id]).groups.flat_map(&:id)
        
        groups_per_assessor = (group_ids.size / assessors.size.to_f).ceil
        groups_split = group_ids.each_slice(groups_per_assessor).to_a

        assessors = {}
        
        mark_scheme["sections"][section_index]["facilitators"].keys.each_with_index do |assessor, i|
            assessors[assessor] = groups_split[i]
        end
        
        # Update the mark scheme
        mark_scheme["sections"][section_index]["facilitators"] = assessors
        milestone.json_data = mark_scheme

        unless milestone.save
            flash.alert = "Failed to automatically assign teams for section."
        end
        
        # Rerender the section to update table row
        render partial: "section_facilitators", locals: {mark_scheme: milestone.json_data}
    end

    def show
        session[:current_project_id] = params[:project_id].to_i

        @current_project = CourseProject.find(session[:current_project_id])
        @mark_scheme = get_mark_scheme
    end

    def show_new
        # Show a given team's marking results table
        @current_project = CourseProject.find(session[:current_project_id])
        
        group = @current_project.groups.find_by(name: params[:group_name])
        @mark_scheme = get_mark_scheme
        
        unless group.nil?    
            @marks = @mark_scheme.milestone_responses.select{|ms| ms.json_data["group_id"] == group.id}.first
        end
        
        render partial: "marking_table"
    end

  private
    def hash_to_json(h)
        # Helper to convert a hash to a json, useful so accessing the data is consistently by strings,
        # like if it was loaded from the database. 
        JSON.parse(h.to_json)
    end

    def get_mark_scheme
        # Only one mark scheme per project 
        Milestone.select{|m| m.system_type == "marking_deadline" &&
            m.course_project_id == session[:current_project_id]}.first
    end
end