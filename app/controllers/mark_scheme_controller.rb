class MarkSchemeController < ApplicationController
  load_and_authorize_resource :milestone_response

  def index
      # TODO: Get the actual current project
      @current_project = CourseProject.find_by(name: "TurtleBot Project")
      session[:current_project_id] = @current_project.id
  
      authorize! :read, @current_project

      

  end

  def new
      session[:mark_scheme] = hash_to_json({ 
          "sections": [],
      })
  end

  def edit
      mark_scheme = get_mark_scheme
      if mark_scheme.nil?
          redirect_to mark_scheme_new_path # TODO: Test this redirect
      end

      session[:mark_scheme] = mark_scheme.json_data
  end

  def add_section
      # TODO: Facilitators will be like {facilitator_id: {team_id, team_id, team_id}} for each of their teams.
      section = {title: params[:section_title], description: "", max_marks: 0, facilitators: {}}
      session[:mark_scheme]["sections"] << hash_to_json(section)
      
      # Render a new section, if i re-rendered the whole mark scheme, it would reset the textareas and inputs.
      render partial: "section", locals: {
          section_index: session[:mark_scheme]["sections"].length - 1, 
          section_title: params[:section_title], 
          section_description: "", 
          max_marks: 0}
  end

  def delete_section
      # TODO: Can we just provide the section index from the js?
      target_index = -1 
      session[:mark_scheme]["sections"].each_with_index do |section, i|
          if section["title"] == params[:section_title]
              target_index = i
              next
          end
      end

      unless target_index == -1
          return render json: {status: "success"}
      end

      render json: {status: "error", message: "Failed to find matching section to remove."}
  end

  def save
      # NOTE: Everything is taken from the inputs, the session is only used for rendering stuff.
      if params[:sections].length < 1 
          return render json: { 
              status: "error", 
              message: "Must have at least one section!" 
          }
      end

      data_valid = true

      params[:sections].each do |section|
          # Ensure the max marks is valid
          if section["max_marks"] =~ /\A\d+\z/
              puts section["max_marks"], "IS INT"
          else
              data_valid = false
          end
      end

      unless data_valid
          # TODO: Show error that that mark value is false. We should never get here really.
          #render json: {""}
      end

      milestone = get_mark_scheme

      session[:mark_scheme]["sections"] = hash_to_json(params[:sections])

      # Create or update milestone to represent the form
      if milestone.nil?
          milestone = Milestone.new(
              json_data: session[:mark_scheme],
              deadline: Date.current.strftime("%Y-%m-%d"), # TODO: Must sort this as this will break the notifcation stuff.
              milestone_type: :team, # Marks will be given per team
              course_project_id: session[:current_project_id]
          )
      else
          milestone.json_data = session[:mark_scheme]
          milestone.deadline = Date.current.strftime("%Y-%m-%d") # TODO: What is this deadline? Should actually use for dealdine.
      end
      
      # This is how we differentiate between the different things milestones are used for
      # TODO: This should be done with a constant somewhere maybe or an enum?
      milestone.json_data["name"] = "mark_scheme"

      # Handle save failure
      unless milestone.save
          return render json: { 
              status: "error", 
              message: "Failed to save milestone when save mark scheme." 
          }
      end

      # TODO: Scuffed but works, should make better later on.
      # TODO: I think i can just redirect_to here maybe
      render json: { 
          status: 'success', 
          message: 'Saved mark scheme', 
          redirect: mark_scheme_index_path
      }
  end
  
  private
      def hash_to_json(h)
          # Helper to convert a hash to a json, useful so accessing the data is consistently by strings,
          # like if it was loaded from the database. 
          JSON.parse(h.to_json)
      end

      def get_mark_scheme
          # Only one mark scheme per project 
          Milestone.select{|m| m.json_data["name"] == "mark_scheme" &&
              m.course_project_id == session[:current_project_id]}.first
      end

end