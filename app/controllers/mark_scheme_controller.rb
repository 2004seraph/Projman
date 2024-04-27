class MarkSchemeController < ApplicationController
  load_and_authorize_resource :milestone_response

  def index
    # TODO: Get the actual current project
    @current_project = CourseProject.find_by(name: "TurtleBot Project")
    session[:current_project_id] = @current_project.id

    authorize! :read, @current_project

    @mark_scheme = get_mark_scheme.json_data
    
  end

  def new
    mark_scheme = get_mark_scheme
    if mark_scheme.nil?
        session[:mark_scheme] = hash_to_json({ 
            "sections": [],
        })
    else    
        redirect_to edit_mark_scheme_path(id: mark_scheme.id)
    end
  end

  def edit
      mark_scheme = get_mark_scheme
      if mark_scheme.nil?
        redirect_to new_mark_scheme_path
      else
        session[:mark_scheme] = mark_scheme.json_data
      end
  end

    def add_section
        # TODO: Section title's can be primary keys?


        # Facilitators would be a list of the facilitator emails and then the marking is split evenly. 
        section = {title: params[:section_title], description: "", max_marks: 0, facilitators: {}}
        session[:mark_scheme]["sections"] << hash_to_json(section)
        
        # Render a new section, if i re-rendered the whole mark scheme, it would reset the textareas and inputs.
        render partial: "section", locals: {
            section_index: session[:mark_scheme]["sections"].length - 1, 
            section_title: params[:section_title], 
            section_description: "",
            section_facilitators: {},
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

    # TEMP: Facilitator id as just me, i MUST figure out how to do the assigning
    #facilitators = AssignedFacilitator.select{|af| af.course_project_id == session[:current_project_id]}.map{|af| af.get_email}.uniq

    #params[:sections][0]["facilitators"] = facilitators

    # TODO: Facilitators should actually be facilitator_id/email : teams see: https://app.moqups.com/srCDKGHkIVEKabrYabQBYyOdCP69e3ax/edit/page/a9d9a3ee1
    session[:mark_scheme]["sections"] = hash_to_json(params[:sections])

    # Create or update milestone to represent the form
    if milestone.nil?
        milestone = Milestone.new(
            json_data: session[:mark_scheme],
            deadline: Date.current.strftime("%Y-%m-%d"), # TODO: Must sort this as this will break the notifcation stuff.
            milestone_type: :team, # Marks will be given per team
            course_project_id: session[:current_project_id],
            system_type: :marking_deadline
        )
    else
        milestone.json_data = session[:mark_scheme]
        milestone.deadline = Date.current.strftime("%Y-%m-%d") # TODO: What is this deadline? Should actually use for dealdine.
    end

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

    def search_facilitators
        # Return all possible facilitators for the current project, given the search criteria.
        query = params[:query]

        @results = AssignedFacilitator.select{|f| f.course_project_id == session[:current_project_id] && 
            f.get_email.include?(query)}

        render json: @results.map{|r| r.get_email}
    end
  
    def add_to_facilitators_selection
        # TODO: How do i get the section here.....
        puts "\n\n"
        puts params + " yoyooyoyoyo"      
        puts "\n\n"
    end

    def clear_facilitators_selection
        # TODO: How do i get the section here.....
        session[:mark_scheme][:sections][] = []
    end

  
  private
      def hash_to_json(h)
          # Helper to convert a hash to a json, useful so accessing the data is consistently by strings,
          # like if it was loaded from the database. 
          JSON.parse(h.to_json)
      end

      def get_mark_scheme
          # Only one mark scheme per project 
          # TODO: The enum doesn't seem to work, only works when used as string to compare.
          Milestone.select{|m| m.system_type == "marking_deadline" &&
              m.course_project_id == session[:current_project_id]}.first
      end

end