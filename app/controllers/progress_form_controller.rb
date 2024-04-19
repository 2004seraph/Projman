class ProgressFormController < ApplicationController
  def index
    @current_project = CourseProject.find_by(name: "TurtleBot Project")
    session[:current_project_id] = @current_project.id

    @progress_forms = Milestone.where(course_project_id: session[:current_project_id]).sort_by{ |m| Date.strptime(m.json_data["release_date"], "%Y-%m-%d") }
    @progress_form = @progress_forms.last
  end

  def show
  end

  def new
    # Reset form data
    session[:new_progress_form] = {
      questions: [],
    }
  end

  def add_question
    session[:new_progress_form][:questions] << params[:question]

    render partial: "question", 
      locals: 
        {
          question: params[:question],
          question_response: "", 
          question_count: session[:new_progress_form][:questions].length,
          facilitator: false
        }
  end

  def save_form
    if session[:new_progress_form][:questions].length < 1 
      return render json: { status: "error", message: "Must have at least one question" }
    end
    
    session[:new_progress_form][:release_date] = params[:release_date]
    session[:new_progress_form][:attendance] = params[:attendance]

    # TEMP: WHEN TESTING - WE ARE JUST SAYING THIS IS THE SELECTED PROJECT FOR THE MODULE LEADER
    session[:current_project_id] = CourseProject.find_by(name: "TurtleBot Project").id

    milestone = Milestone.new(
      json_data: session[:new_progress_form],
      deadline: Date.current.strftime("%Y-%m-%d"),
      milestone_type: :team,
      course_project_id: session[:current_project_id]
    )

    # Handle save failure
    unless milestone.save
      return render json: { status: "error", message: "Failed to save milestone when save_form." }
    end
  
    # TODO: Scuffed but works, should make better later on.
    # TODO: I think i can just redirect_to here maybe
    render json: { status: 'success', message: 'Saved form', redirect: progress_form_index_path }
  end

  def show_new
    if params[:release_date] == "" then return end

    project = CourseProject.find(session[:current_project_id])
    @progress_form = Milestone.select{|m| m.course_project_id == session[:current_project_id] && m.json_data["release_date"] == params[:release_date]}.first
    
    unless params[:group_name] == "None"
      group = CourseProject.find(session[:current_project_id]).groups.find_by(name: params[:group_name])

      @progress_response = @progress_form.milestone_responses.select{
        |mr| mr.json_data["group_id"] == group.id
      }.first

    else
      group = params[:group_name]
    end
    
    render partial: "progress_form", locals: 
      {
        progress_form: @progress_form.json_data,
        progress_response: @progress_response.nil? ? nil : @progress_response.json_data,
        group: group,
        facilitator: false
      }
  end
end