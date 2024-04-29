class ProgressFormController < ApplicationController
  authorize_resource :milestone_response

  def index
    # TODO: Get the actual current project
    @current_project = CourseProject.find_by(name: "TurtleBot Project")
    session[:current_project_id] = @current_project.id

    authorize! :read, @current_project

    # Get each progress form
    @progress_forms = get_progress_forms_for_project.sort_by{ |pf| pf.deadline }

    # Auto select the one with the furthest release date
    @progress_form = @progress_forms.last
    session[:progress_form_id] = @progress_form.nil? ? -1 : @progress_form.id
  end

  def new
    # Initialise new form
    # NOTE: Will not work without parse and to_json because its loaded from db as json
    #       so this just keeps it always as json.
    session[:new_progress_form] = JSON.parse({ 
      "questions": [], 
      "attendance": true 
    }.to_json)

    session[:progress_form_deadline] = ""

    @progress_form_json = session[:new_progress_form] # TODO: Remove this? Can just use session in view.
    @progress_form_deadline = ""
  end

  def edit
    progress_form = Milestone.find(params[:id])
    if progress_form.nil?
      # TODO: Show error maybe just as popup modal?
      puts "[ERROR] TODO: Handle error when cannot find progress form by id in edit."
      redirect_to progress_form_index_path
      return
    end

    # Can't edit released forms
    if progress_form.deadline <= Date.today
      # TODO: Show error maybe just as popup modal?
      redirect_to progress_form_index_path
      return
    end

    session[:new_progress_form] = progress_form.json_data
    session[:progress_form_deadline] = progress_form.deadline

    @progress_form_json = session[:new_progress_form] # TODO: Remove this? Can just use session in view.
    @progress_form_deadline = progress_form.deadline
  end

  # AJAX Routes
  def add_question
    if session[:new_progress_form]["questions"].nil?
      session[:new_progress_form]["questions"] = []
    end

    session[:new_progress_form]["questions"] << params[:question]

    render partial: "progress_form",
      locals: 
        {
          progress_form_id: -1, # TODO: Remove this.
          progress_form: session[:new_progress_form],
          release_date: session[:progress_form_deadline],
          progress_response: nil, 
          group: "None", 
          facilitator: false,
          editing_form: true
        }
  end

  def delete_question
    if params[:question_index] < 0 || params[:question_index] >= session[:new_progress_form]["questions"].length 
      puts "[ERROR] TODO: Handle error when question index is invalid in remove_question"
    end

    # TODO: This is invalid because this won't render the right stuff for when we're viewing questions

    session[:new_progress_form]["questions"].delete_at(params[:question_index])

    # TODO: Must be able to fill in actual data on the rerender.
    # TODO: FILL IN ACTUAL DETAILS HERE
    render partial: "progress_form",
      locals: 
        {
          progress_form: JSON.parse(session[:new_progress_form].to_json),
          release_date: session[:progress_form_deadline],
          progress_response: nil, 
          group: "None", 
          facilitator: false,
          editing_form: true # Force editable because release date not set yet
        }
  end

  def save_form
    # To save the form there must be at least one question
    # TODO: Do we actually want to enforce this? Really it doesn't matter that much.
    if session[:new_progress_form]["questions"].length < 1 
      return render json: { 
        status: "error", 
        message: "Must have at least one question!" 
      }
    end

    # Try find a pre-existing form to update
    milestone = get_progress_forms_for_project.select{
      |m| m.deadline == session[:progress_form_deadline]
    }.first

    # Update progress form, must be after get milestone incase 'primary key' changes 
    session[:new_progress_form]["attendance"] = params[:attendance]

    # HTML date formatted like this 2024-04-29T17:25    

    formatted_deadline = params[:release_date].gsub("T", " ")

    # Create or update milestone to represent the form
    if milestone.nil?
      milestone = Milestone.new(
        json_data: session[:new_progress_form],
        deadline: formatted_deadline,
        milestone_type: :team,
        course_project_id: session[:current_project_id],
        #system_type: :progress_form_deadline TODO: This was removed for some reason?
      )
    else
      milestone.json_data = session[:new_progress_form]
      milestone.deadline = formatted_deadline
    end

    milestone.json_data["name"] = "progress_form" # TODO: Temp, determining what is a progress form.

    # Handle save failure
    unless milestone.save
      return render json: { 
        status: "error", 
        message: "Failed to save milestone when save_form." 
      }
    end
  
    # TODO: Scuffed but works, should make better later on.
    # TODO: I think i can just redirect_to here maybe
    render json: { 
      status: 'success', 
      message: 'Saved form', 
      redirect: progress_form_index_path
    }
  end

  def delete_form
    # TODO: Need to make composite primary key with release date and name of form?
    milestone = get_progress_forms_for_project.select{
      |m| m.deadline == session[:progress_form_deadline]
    }.first

    if milestone.nil?
      session[:new_progress_form] = {}
    else
      milestone.destroy
    end
  
    # TODO: Scuffed but works, should make better later on.
    # TODO: I think i can just redirect_to here maybe
    render json: { 
      status: 'success', 
      message: 'Deleted form', 
      redirect: progress_form_index_path 
    }

  end

  def show_new # TODO: Should this just be show?
    if params[:release_date] == "" then 
      return 
    end

    # Update the current displayed form
    formatted_release_date = DateTime.parse(params[:release_date].gsub("T", " "))
    
    @progress_form = get_progress_forms_for_project.select{
      |m| date_to_string(m.deadline) == date_to_string(formatted_release_date)
    }.first
    
    session[:progress_form_id] = @progress_form.id

    # Handle group not being specified
    unless params[:group_name] == "None"
      group = CourseProject.find(session[:current_project_id]).groups.find_by(name: params[:group_name])

      @progress_response = @progress_form.milestone_responses.select{
        |mr| mr.json_data["group_id"] == group.id
      }.first

    else
      group = params[:group_name]
    end
    
    # Return the html for the new progress form
    render partial: "progress_form", locals:
      {
        progress_form_id: @progress_form.id, 
        progress_form: @progress_form.json_data,
        release_date: @progress_form.deadline,
        progress_response: @progress_response.nil? ? nil : @progress_response.json_data,
        group: group,
        facilitator: false,
        editing_form: false
      }
  end

  private
    def get_progress_forms_for_project
      # Helper for returning the correct milestones
      #Milestone.select{
      #  |m| m.system_type == "progress_form_deadline" && 
      #  m.course_project_id == session[:current_project_id]
      #}

      Milestone.select{
        |m| m.json_data["name"] == "progress_form" && 
        m.course_project_id == session[:current_project_id]
      }
    end

  def date_to_string(date)
    date.strftime("%d/%m/%Y %H:%M")
  end
end