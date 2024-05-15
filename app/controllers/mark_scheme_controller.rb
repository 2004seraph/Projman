# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MarkSchemeController < ApplicationController
  skip_authorization_check

  def index
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    authorize! :update, @current_project

    milestone = get_mark_scheme
    return if milestone.nil?

    @mark_scheme = milestone.json_data
  end

  def new
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    authorize! :update, @current_project

    mark_scheme = get_mark_scheme
    if mark_scheme.nil?
      session[:mark_scheme] = hash_to_json({
        "sections": []
      })
    else
      redirect_to edit_project_mark_scheme_path(id: mark_scheme.id)
    end
  end

  def edit
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])

    authorize! :update, @current_project

    mark_scheme = get_mark_scheme
    if mark_scheme.nil?
      redirect_to new_project_mark_scheme_path
    else
      session[:mark_scheme] = mark_scheme.json_data
    end
  end

  def add_section
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Assessors would be a list of the assessor emails and then the marking is split evenly.
    section_title = params[:section_title]

    if session[:mark_scheme]['sections'].map{|s| s['title']}.include?(section_title)
      @error = 'Cannot have duplicate section titles.'

    elsif section_title.blank?
      @error = 'Section title cannot be empty.'

    else
      section = { title: params[:section_title], description: '', max_marks: 0 }
      session[:mark_scheme]['sections'] << hash_to_json(section)
    end

    return unless request.xhr?

    respond_to(&:js)
  end

  def delete_section
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Find the section with the matching title and remove it
    target_index = -1
    session[:mark_scheme]["sections"].each_with_index do |section, i|
      if params["section_title"] == section["title"]
        target_index = i
        next
      end
    end

    return render json: { status: "error", message: "Failed to find matching section to remove." } if target_index == -1

    session[:mark_scheme]["sections"].delete_at(target_index)

    render json: { status: "success" }
  end

  def save
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Everything is taken from the inputs, the session is only used for rendering stuff.
    if params[:sections].empty?
      return render json: {
        status:  "error",
        message: "Must have at least one section!"
      }
    end

    # Ensure max marks are valid or return error
    params[:sections].each do |section|
      if !/\A\d+\z/.match?(section["max_marks"])
        return render json: {
          status:  "error",
          message: "Max marks must be a positive whole number."
        }
      end
    end

    milestone = get_mark_scheme

    # Update section data without resetting assigned assessors
    params[:sections].each_with_index do |section, i|
      session[:mark_scheme]["sections"][i]["title"] = section["title"]
      session[:mark_scheme]["sections"][i]["description"] = section["description"]
      session[:mark_scheme]["sections"][i]["max_marks"] = section["max_marks"]
    end

    # Create or update milestone to represent the form
    if milestone.nil?
      milestone = Milestone.new(
        json_data:         session[:mark_scheme],
        deadline:          Date.current.strftime("%Y-%m-%d"), # Deadline isn't used here
        milestone_type:    :team, # Marks will be given per team
        course_project_id: params[:project_id],
        system_type:       :marking_deadline
      )
    else
      milestone.json_data = session[:mark_scheme]
      milestone.deadline = Date.current.strftime("%Y-%m-%d") # Deadline isn't used here
    end

    # Handle save failure
    unless milestone.save
      return render json: {
        status:  "error",
        message: "Failed to save milestone when save mark scheme."
      }
    end

    # Can't redirect from ajax here, so must do it from js
    render json: {
      status:   "success",
      message:  "Saved mark scheme",
      redirect: project_mark_scheme_index_path
    }
  end

  def search_assessors
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Return all possible assessors for the current project, given the search criteria.
    query = params[:query]

    query = "" if query.nil?

    @results = Staff.select { |s| s.email.include?(query.downcase) }
    render json: @results.map(&:email)
  end

  def add_to_assessors_selection
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Section index is not a param in the confirm ajax, so set it here to use there.
    session[:current_section_index] = params[:section_index]

    # Handle invalid email by just not adding to selected
    return if Staff.where(email: params[:section_assessor_email]).first.nil?

    @assessor_email = params[:section_assessor_email]

    if @assessor_email.present?
      if session[:assessor_selection].nil?
        session[:assessor_selection] = [@assessor_email]
      elsif !(session[:assessor_selection].to_a.include?(@assessor_email))
        session[:assessor_selection] << @assessor_email
      else
        @assessor_email = nil
      end
    
    end

    if request.xhr?
      respond_to(&:js)
    else
      render :new
    end
  end

  def add_assessors_selection
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    section_index = session[:current_section_index].to_i

    milestone = get_mark_scheme
    mark_scheme = milestone.json_data

    # Initialise assessors if necessary
    mark_scheme["sections"][section_index]["assessors"] = {} if mark_scheme["sections"][section_index]["assessors"].nil?

    # Populate new assessor emails into mark scheme milestone json data
    session[:assessor_selection].each do |assessor|
      unless mark_scheme["sections"][section_index]["assessors"].include?(assessor)
        mark_scheme["sections"][section_index]["assessors"][assessor] = []
      end
    end

    # Update the mark scheme
    milestone.json_data = mark_scheme
    flash.alert = "Failed to assign assessors to mark scheme." unless milestone.save

    # Re-render the view for assessors
    @mark_scheme = milestone.json_data

    if request.xhr?
      respond_to(&:js)
    else
      render :new
    end
  end

  def remove_from_assessor_selection
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    @assessor_email = params[:item_text].strip
    session[:assessor_selection].delete(@assessor_email)
  end

  def clear_assessors_selection
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Reset assessor selection, only called when modal is first opened
    session[:assessor_selection] = []
  end

  def remove_assessor_from_section
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    mark_scheme = get_mark_scheme
    mark_scheme.json_data["sections"][params[:section_index]]["assessors"].delete(params[:email])

    flash.alert = "Failed to unassign assessor from section." unless mark_scheme.save

    render partial: "section_assessors", locals: { mark_scheme: mark_scheme.json_data }
  end

  def get_assignable_teams
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Return the remaining teams available to be assigned to a assessor for the given section
    # Also contains teams already assigned to the assessor

    groups = CourseProject.find(session[:current_project_id]).groups

    mark_scheme = get_mark_scheme

    section = mark_scheme.json_data["sections"][params[:section_index]]

    # Save params for submit modal
    session[:current_section_index] = params[:section_index]
    session[:current_assessor_email] = params[:email]

    groups_to_show = {}
    groups.each do |group|
      groups_to_show[group.name] = { id: group.id, already_assigned: false }
    end

    section["assessors"].each do |assessor, team_ids|
      team_ids.each do |team_id|
        team = Group.find(team_id)
        if assessor == params[:email]
          groups_to_show[team.name][:already_assigned] = true
        else
          groups_to_show.delete(team.name)
        end
      end
    end

    render json: { groups_to_show: groups_to_show.values }
  end

  def assign_teams
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Actually assign the selected teams from the modal to the chosen assessor
    section_index = session[:current_section_index].to_i

    milestone = get_mark_scheme
    mark_scheme = milestone.json_data

    # Get all the team ids that are taken, so we don't assign twice, incase someone inspects element.
    taken_teams = mark_scheme["sections"][section_index]["assessors"].reject do |email, _|
      email == session[:current_assessor_email]
    end.values.flatten

    new_teams = params[:team_ids] - taken_teams
    mark_scheme["sections"][section_index]["assessors"][session[:current_assessor_email]] = new_teams

    milestone.json_data = mark_scheme

    flash.alert = "Failed to assign teams to assessor." unless milestone.save

    # Re-render the section to update table row
    render partial: "section_assessors", locals: { mark_scheme: milestone.json_data }
  end

  def auto_assign_teams
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project
    # Auto assign teams to all the chosen assessors for a section
    section_index = params[:section_index].to_i

    milestone = get_mark_scheme
    mark_scheme = milestone.json_data

    assessors = mark_scheme["sections"][section_index]["assessors"]

    return render partial: "section_assessors", locals: { mark_scheme: milestone.json_data } if assessors.blank?

    # Split the teams between the assessors evenly
    group_ids = CourseProject.find(session[:current_project_id]).groups.flat_map(&:id)

    groups_per_assessor = (group_ids.size / assessors.size.to_f).ceil
    groups_split = group_ids.each_slice(groups_per_assessor).to_a

    assessors = {}

    mark_scheme["sections"][section_index]["assessors"].keys.each_with_index do |assessor, i|
      assessors[assessor] = groups_split[i]
    end

    # Update the mark scheme
    mark_scheme["sections"][section_index]["assessors"] = assessors
    milestone.json_data = mark_scheme

    flash.alert = "Failed to automatically assign teams for section." unless milestone.save

    # Rerender the section to update table row
    render partial: "section_assessors", locals: { mark_scheme: milestone.json_data }
  end

  def marks
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    session[:current_project_id] = params[:project_id].to_i

    @current_project = CourseProject.find(session[:current_project_id])
    @mark_scheme = get_mark_scheme
    authorize! :update, @current_project
  end

  def show_new
    session[:current_project_id] = params[:project_id].to_i
    @current_project = CourseProject.find(session[:current_project_id])
    # Show a given team's marking results table
    @current_project = CourseProject.find(session[:current_project_id])
    authorize! :update, @current_project

    group = @current_project.groups.find_by(name: params[:group_name])
    @mark_scheme = get_mark_scheme

    unless group.nil?
      @marks = @mark_scheme.milestone_responses.select { |ms| ms.json_data["group_id"] == group.id }.first
    end

    render partial: "marking_table"
  end

  def export_mark_scheme_with_results
    mark_scheme = get_mark_scheme

    return if mark_scheme.nil?
    
    csv_data = CSV.generate(headers: true) do |csv|
      # Write headers
      csv << ["Team Name", "Section Title", "Marks Given", "Reason", "Assessor"]
      
      # Write data
      mark_scheme.milestone_responses.each do |mr| 
        data = mr.json_data
        
        team = Group.find(data["group_id"].to_i)

        data["sections"].each do |section_title, section_data|
          # Must convert empty values to nil here otherwise they are wrote to the csv as ""
          marks_given = section_data["marks_given"].empty? ? nil : section_data["marks_given"]
          reason = section_data["reason"].empty? ? nil : section_data["reason"]
          assessor = section_data["assessor"].empty? ? nil : section_data["assessor"]
          
          csv << [
            team.name, 
            section_title, 
            marks_given, 
            reason, 
            assessor
          ]
        end
      end
    end
    
    # Send the data as an attachment to download
    filename = "#{mark_scheme.course_project.name}-marking.csv".gsub(' ', '-')
    send_data csv_data, filename: filename, type: 'text/csv'
  end

  def import_mark_scheme
    # Uses the given csv file to generate a mark scheme milestone

    unless params[:mark_scheme_csv].present?
      @error = "Must select a mark scheme to import."

    else
      mark_scheme_csv = CSV.new(params[:mark_scheme_csv].tempfile)
      
      @mark_scheme_json = hash_to_json({"sections": []})

      mark_scheme_csv.each do |row|
        title = row[0]
        description = row[1]
        max_marks = row[2]
        
        unless title.present? && description.present? && /\A\d+\z/.match(max_marks)
          @error = "Invalid CSV format."
          break
        end

        @mark_scheme_json['sections'] << hash_to_json({ title: title, description: description, max_marks: max_marks })
      end
    end

    unless @error.present?
      # Mark scheme json succesfully parsed, so destroy existing milestone to destroy responses as well
      # TODO: When I edit a mark scheme should I also be destroying the responses to it? Or just the responses where
      #       something has been changed?
      get_mark_scheme&.destroy
      
      # Create a new milestone
      milestone = Milestone.new(
        json_data: hash_to_json(@mark_scheme_json),
        deadline: Date.current.strftime('%Y-%m-%d'),  # Deadline isn't used for mark schemes
        milestone_type: :team,                        # Marks will be given per team
        course_project_id: params[:project_id],
        system_type: :marking_deadline
      )

      @error = "Failed to import mark scheme." unless milestone.save
    end

    if request.xhr?
      respond_to(&:js)
    else
      render :new
    end
  end

  private
    def hash_to_json(h)
      # Helper to convert a hash to a json, useful so accessing the data is consistently by strings,
      # like if it was loaded from the database.
      JSON.parse(h.to_json)
    end

    def get_mark_scheme
      # Only one mark scheme per project
      Milestone.select do |m|
        m.system_type == "marking_deadline" &&
          m.course_project_id == session[:current_project_id]
      end.first
    end
end
