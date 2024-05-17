# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

require "json"

class CourseProjectController < ApplicationController
  load_and_authorize_resource

  skip_before_action :verify_authenticity_token, only: %i[
    toggle_project_choices
    create
  ]

  def index
    if current_user.is_admin?
      @projects = CourseProject.all
      @course_modules = CourseModule.all.length
      render "index_module_leader"
    elsif current_user.is_staff?
      @projects = current_user.staff.course_projects
      @course_modules = current_user.staff.course_modules.length
      render "index_module_leader"
    elsif current_user.is_student?
      @live_projects = current_user.student.course_projects.where(status: ["preparation", "review", "live"])
      @comp_projects = current_user.student.course_projects.where(status: "completed")

      @milestones = []
      @live_projects.each do |project|
        @milestones += project.milestones
      end
      render "index_student"
    else
      Sentry.capture_message("could not find user: #{current_user.student}", level: :warn)
    end
  end

  def new
    session[:context] = "new"
    staff_id = Staff.where(email: current_user.email).first
    @min_date = "#{DateTime.now.strftime('%Y-%m-%dT:%H:%M')}"

    modules_hash = if current_user.is_admin?
      CourseModule.all.order(:code).pluck(:code, :name).to_h
    else
      CourseModule.all.where(staff_id:).order(:code).pluck(:code, :name).to_h
    end
    # if a staff is not a module lead for any module, do not show them the new page
    if modules_hash.empty?
      flash[:alert] = "You are not part of any modules. Please contact an admin if this is in error."
      redirect_to session[:redirect_url] # previous page, or `action: :index` if you prefer
    end

    team_allocation_modes_hash = CourseProject.team_allocations
    milestone_types_hash = Milestone.milestone_types

    session[:project_data] = {
      errors:                        {},
      modules_hash:,
      team_allocation_modes_hash:,
      milestone_types_hash:,
      status:                        "draft",
      selected_module:               "",
      project_name:                  "",
      teams_from_project_choice:     false,
      project_choices:               [],
      team_size:                     4,
      selected_team_allocation_mode: "",
      preferred_teammates:           1,
      avoided_teammates:             2,
      project_milestones:            [{ "Name": "Project Deadline", "Date": "", "Type": "team", "system_type": "project_deadline", "Comment": "" },
                                      { "Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student",
           "system_type": "teammate_preference_deadline", "Comment": "" },
                                      { "Name": "Project Preference Form Deadline", "Date": "", "Type": "team",
           "system_type": "project_preference_deadline", "Comment": "" }],
      project_facilitators:          [],

      facilitator_selection:         [],
      project_choices_enabled:       true
    }
  end

  def edit
    session[:context] = "edit"
    project_id = params[:id]
    project = CourseProject.find_by(id: project_id)

    possible_status_changes = []

    datenow = DateTime.now.strftime('%Y-%m-%dT%H:%M')

    if project.status == 'draft'
      @min_date = datenow
    else
      @min_date = DateTime.parse(project.created_at.to_s).strftime('%Y-%m-%dT%H:%M')
    end

    # if we are in preparation or review, we can go to those two or also go live
    p_deadline = project.milestones.find_by(system_type: "project_deadline")
    if project.status == "preparation" || project.status == "review"
      possible_status_changes = ["preparation", "review", "live"]
    # if we are in live and deadline hasnt passed, we cant change to anything
    elsif project.status == "live" && p_deadline && p_deadline.deadline > datenow
      possible_status_changes = ["live"]
    # if we are live, and project deadline has passed, we can either go to completed or archived, or stay in live
    elsif project.status == "live" && p_deadline && p_deadline.deadline < datenow
      possible_status_changes = ["completed", "archived", "live"]
    # if compeleted, we can only go to archived, or completed
    elsif project.status == "completed"
      possible_status_changes = ["completed", "archived"]
    elsif project.status == "archived"
      possible_status_changes = ["archived"]
    end

    staff_id = Staff.where(email: current_user.email).first
    if current_user.is_admin?
      modules_hash = CourseModule.all.order(:code).pluck(:code, :name).to_h
    else
      modules_hash = CourseModule.all.where(staff_id:).order(:code).pluck(:code, :name).to_h
    end
    # if a staff is not a module lead for any module, do not show them the new page
    if modules_hash.empty?
      flash[:alert] = "You are not part of any modules. Please contact an admin if this is in error."
      redirect_to session[:redirect_url] # previous page, or `action: :index` if you prefer
    end

    team_allocation_modes_hash = CourseProject.team_allocations
    milestone_types_hash = Milestone.milestone_types

    project_choices = project.subprojects.pluck(:name)
    project_milestones = project.milestones.where(user_generated: true)
    project_assigned_facilitators = project.assigned_facilitators
    project_facilitators = []
    project_assigned_facilitators.each do |facilitator|
      project_facilitators << Staff.find(facilitator[:staff_id])[:email] if facilitator[:staff_id].present?
      project_facilitators << Student.find(facilitator[:student_id])[:email] if facilitator[:student_id].present?
    end
    project_milestones_parsed = []

    # TODO: Also, ignore any milestones on the project that arent created by a user

    project_milestones.each do |milestone_data|
      date_time_string = milestone_data[:deadline].to_s
      parsed_datetime = DateTime.parse(date_time_string)
      parsed_date = parsed_datetime.strftime("%Y-%m-%d")
      parsed_time = parsed_datetime.strftime("%H:%M")

      json_data = milestone_data[:json_data]
      milestone = {
        "Name":        json_data["Name"],
        "Date":        "#{parsed_date}T#{parsed_time}",
        "Type":        milestone_data[:milestone_type],
        "system_type": milestone_data[:system_type],
        "Comment":     json_data["Comment"]
      }
      milestone["Email"] = json_data["Email"] if json_data.key?("Email")
      project_milestones_parsed << milestone
    end
    # add preference form milestones, if missing. (they arent pushed if they dont apply at the time)
    project_deadline = project_milestones_parsed.find { |m| m[:system_type] == "project_completion_deadline" }[:Date]
    team_pref_deadline = ""
    proj_pref_deadline = ""
    if (milestone = project_milestones_parsed.find { |m| m[:system_type] == "teammate_preference_deadline" })
      team_pref_deadline = milestone[:Date]
    else
      project_milestones_parsed << { "Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student",
                                     "system_type": "teammate_preference_deadline", "Comment": "" }
    end
    if (milestone = project_milestones_parsed.find { |m| m[:system_type] == "project_preference_deadline" })
      proj_pref_deadline = milestone[:Date]
    else
      project_milestones_parsed << { "Name": "Project Preference Form Deadline", "Date": "", "Type": "team",
                                     "system_type": "project_preference_deadline", "Comment": "" }
    end

    session[:project_data] = {
      errors:                            {},
      modules_hash:,
      team_allocation_modes_hash:,
      milestone_types_hash:,

      selected_status:                   project[:status],
      status:                            project[:status],
      possible_status_changes:,
      selected_module:                   CourseModule.find(project[:course_module_id])[:code],
      project_name:                      project[:name],
      teams_from_project_choice:         project[:teams_from_project_choice],
      project_choices:,
      team_size:                         project[:team_size],
      selected_team_allocation_mode:     project[:team_allocation],
      preferred_teammates:               project[:preferred_teammates],
      avoided_teammates:                 project[:avoided_teammates],
      project_milestones:                project_milestones_parsed,
      project_deadline:,
      teammate_preference_form_deadline: team_pref_deadline,
      project_preference_form_deadline:  proj_pref_deadline,

      project_facilitators:,

      facilitator_selection:             [],
      project_choices_enabled:           project_choices.length.positive?
    }
  end

  # POST
  def add_project_choice
    @project_choice_name = params[:project_choice_name]
    session[:project_data][:project_choices] << @project_choice_name

    # If done via AJAX (JavaScript enabled), dynamically add
    if request.xhr?
      respond_to(&:js)

    # Otherwise re-render :new
    else
      rerender_edit_or_new
    end
  end

  def remove_project_choice
    @project_choice_name = params[:item_text].strip
    session[:project_data][:project_choices].delete(@project_choice_name)
    return if request.xhr?

    rerender_edit_or_new
  end

  def add_project_milestone
    @project_milestone_name = params[:project_milestone_name]
    @project_milestone_name.tr("_", " ")
    project_milestone_unique = false
    unless session[:project_data][:project_milestones].any? do |milestone|
             milestone[:Name] == @project_milestone_name
           end
      session[:project_data][:project_milestones] << { "Name": @project_milestone_name, "Date": "", "Type": "",
                                                       "system_type": nil, "Comment": "" }
      project_milestone_unique = true
    end
    if request.xhr?
      respond_to do |format|
        format.js if project_milestone_unique
      end
    else
      rerender_edit_or_new
    end
  end

  def remove_project_milestone
    @project_milestone_name = params[:item_text].strip.match(/^milestone_([^_]+)/)[1]
    filtered_milestones = session[:project_data][:project_milestones].reject do |milestone|
      milestone[:Name] == @project_milestone_name
    end
    session[:project_data][:project_milestones] = filtered_milestones

    if request.xhr?
      respond_to(&:js)
    else
      rerender_edit_or_new
    end
  end

  def clear_facilitator_selection
    session[:project_data][:facilitator_selection] = []
  end

  def add_to_facilitator_selection
    @facilitator_email = params[:project_facilitator_name]
    session[:project_data][:facilitator_selection] << @facilitator_email if @facilitator_email.present?
    if request.xhr?
      respond_to(&:js)
    else
      rerender_edit_or_new
    end
  end

  def remove_from_facilitator_selection
    @facilitator_email = params[:item_text].strip
    session[:project_data][:facilitator_selection].delete(@facilitator_email)
  end

  def add_facilitator_selection
    @facilitators_added = []
    session[:project_data][:facilitator_selection].each do |facilitator|
      unless session[:project_data][:project_facilitators].include?(facilitator)
        session[:project_data][:project_facilitators] << facilitator
        @facilitators_added << facilitator

        begin
          if !(Staff.exists?(email: facilitator))
            staff_member = SheffieldLdapLookup::LdapFinder.new(facilitator)

            if !(staff_member.nil?) && staff_member.lookup[:shefuseraccounttype].include?("staff")
              new_staff = Staff.new(email: facilitator)

              if new_staff.valid?
                new_staff.save
              end
            end
          end
        rescue
        end
      end
    end

    if request.xhr?
      respond_to(&:js)
    else
      rerender_edit_or_new
    end
  end

  def remove_facilitator
    @facilitator_email = params[:item_text]
    session[:project_data][:project_facilitators].delete(@facilitator_email)
  end

  def search_facilitators_student
    query = params[:query]
    @results = Student.where("email LIKE ?", "%#{query}%").limit(8).distinct
    render json: @results.pluck(:email)
  end

  def search_facilitators_staff
    query = params[:query]
    @results = Staff.where("email LIKE ?", "%#{query}%").limit(8).distinct
    render json: @results.pluck(:email)
  end

  def get_milestone_data
    milestone_name = params[:milestone_name].split("_").drop(1).join("_")
    milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
    respond_to do |format|
      format.json { render json: milestone }
    end
  end

  def remove_milestone_email
    milestone_name = params[:milestone_name].split("_").drop(1).join("_")
    milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
    return unless milestone.key?("Email")

    milestone.delete("Email")
  end

  def set_milestone_email_data
    milestone_name = params[:milestone_name].split("_").drop(1).join("_")
    milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }

    # Does it have an email field in the json?
    if milestone.key?("Email")
      milestone["Email"]["Content"] = params[:milestone_email_content]
      milestone["Email"]["Advance"] = params[:milestone_email_advance]
    else
      milestone["Email"] =
        { "Content": params[:milestone_email_content], "Advance": params[:milestone_email_advance] }
    end
  end

  def set_milestone_comment
    milestone_name = params[:milestone_name].split("_").drop(1).join("_")
    milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
    milestone[:Comment] = params[:milestone_comment]
  end

  def create
    session[:project_data][:errors] = {}
    errors = session[:project_data][:errors]

    errors[:top] = []

    project_data = session[:project_data]

    # Main Data
    project_data[:project_name] = params[:project_name]
    project_data[:selected_module] = params[:module_selection]
    errors[:main] = []
    unless CourseModule.exists?(code: project_data[:selected_module])
      errors[:main] << "The selected module does not exist"
    end

    # Project Choices
    project_data[:teams_from_project_choice] = params.key?(:teams_from_project_choice)
    project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
    errors[:project_choices] = []

    if project_data[:project_choices].size <= 1 && project_data[:project_choices_enabled]
      errors[:project_choices] << "Add at least 2 project choices, or disable this section"
    end

    # Team Config
    project_data[:team_size] = params[:team_size]
    project_data[:selected_team_allocation_mode] = params[:team_allocation_method]
    errors[:team_config] = []

    # Team Preference Form
    project_data[:preferred_teammates] = params[:preferred_teammates]
    project_data[:avoided_teammates] = params[:avoided_teammates]
    errors[:team_pref] = []

    # Timings
    project_data[:project_deadline] = params["milestone_Project Deadline_date"]
    project_data[:teammate_preference_form_deadline] = params["milestone_Teammate Preference Form Deadline_date"]
    project_data[:project_preference_form_deadline] = params["milestone_Project Preference Form Deadline_date"]

    errors[:timings] = []

    project_deadline = nil
    if project_data[:project_deadline].blank?
      errors[:timings] << "Please set project deadline"
    else
      project_deadline = DateTime.parse(project_data[:project_deadline])
    end

    project_data[:teams_from_project_choice] = false unless project_data[:project_choices_enabled]

    if (project_data[:project_choices_enabled] && project_data[:teams_from_project_choice]) || project_data[:team_size] == 1
      project_data[:selected_team_allocation_mode] = nil
    end

    if project_data[:selected_team_allocation_mode] == "preference_form_based" && project_data[:teammate_preference_form_deadline].blank?
      errors[:timings] << "Please set team preference form deadline"
    end
    if project_data[:project_choices_enabled] && project_data[:project_preference_form_deadline].blank?
      errors[:timings] << "Please set project preference form deadline"
    end

    params.each do |key, value|
      # Check if the key starts with "milestone_"
      if key.match?(/^milestone_[^_]+_date$/)
        # Extract the milestone name from the key
        milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]

        # Find the corresponding milestone in the milestones hash and update its "Date" value
        if (milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name })
          milestone[:Date] = value
          unless (defined?(value) && value.present?) || !milestone[:system_type].nil?
            err = "Please make sure all milestones have a date"
            errors[:timings] << err unless errors[:timings].include? err
          end
        end
      end

      next unless key.match?(/^milestone_[^_]+_type$/)

      # Extract the milestone name from the key
      milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]

      # Find the corresponding milestone in the milestones hash and update its "Type" value
      next unless (milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name })
      next unless milestone[:system_type].nil?

      milestone[:Type] = value
      unless defined?(value) && value.present? && Milestone.milestone_types.key?(value)
        err = "Please make sure all milestone types are valid"
        errors[:timings] << err unless errors[:timings].include? err
      end
    end

    # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
    if project_data[:selected_team_allocation_mode] != "preference_form_based" &&
       (milestone = session[:project_data][:project_milestones].find do |m|
         m[:Name] == "Teammate Preference Form Deadline"
       end)
      milestone[:Date] = ""
    end
    if !project_data[:project_choices_enabled] &&
       (milestone = session[:project_data][:project_milestones].find do |m|
         m[:Name] == "Project Preference Form Deadline"
       end)
      milestone[:Date] = ""
    end

    # Check if any milestone dates are set to before the minimum value
    session[:project_data][:project_milestones].each do |m|
      date = m[:Date]
      next unless defined?(date) && date.present?

      datetime = DateTime.parse(date)
      if datetime < DateTime.now
        err = "Milestone dates cannot be set to earlier than the current date"
        errors[:timings] << err unless errors[:timings].include? err
      end
      if project_deadline && datetime > project_deadline
        err = "Milestone dates must be set to earlier than the project deadline"
        errors[:timings] << err unless errors[:timings].include? err
      end
    end

    facilitators_not_found = project_data[:project_facilitators].reject do |email|
      Student.exists?(email:) || Staff.exists?(email:)
    end
    errors[:facilitators_not_found] = facilitators_not_found

    no_errors = errors.all? { |_, v| v.empty? }
    # Creating Project Model
    new_project = CourseProject.new(
      course_module:             CourseModule.find_by(code: project_data[:selected_module]),
      name:                      project_data[:project_name],
      # project_choices_json: project_data[:project_choices_enabled] ? project_data[:project_choices].to_json : "[]",
      teams_from_project_choice: project_data[:teams_from_project_choice],
      team_size:                 project_data[:team_size],
      team_allocation:           project_data[:selected_team_allocation_mode].nil? ? nil : project_data[:selected_team_allocation_mode].to_sym,
      preferred_teammates:       project_data[:preferred_teammates],
      avoided_teammates:         project_data[:avoided_teammates],
      status:                    :draft
    )

    if new_project.valid? && no_errors
      new_project.save
    else
      new_project.errors.messages.each do |section, section_errors|
        section_errors.each do |error|
          (errors[section.to_sym] ||= []) << error
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # Create sub projects models and associate them to this project
    if no_errors
      subprojects = []
      if project_data[:project_choices_enabled]
        project_data[:project_choices].each do |project_choice|
          subproject = Subproject.new(
            name:              project_choice,
            json_data:         "{}",
            course_project_id: new_project.id
          )
          subprojects << subproject
        end
      end
      subprojects.each do |subproject|
        if subproject.valid?
          subproject.save
        else
          new_project.destroy
          subproject.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:timings].include?("Subproject error: #{attribute} : #{message}")
                errors[:timings] << "Subproject error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # Creating associated milestones
    if no_errors
      milestones = []
      project_data[:project_milestones].each do |milestone_data|
        # dd/mm/yyyy to yyyy-mm-dd
        date_time_string = milestone_data[:Date]
        # This did a funny where sometimes the format was recieved as m/d/y, hasnt happened again since what should have fixed it
        # puts date_string
        next if date_time_string.blank? # dont push the milestone if its not got a set date

        date, time = date_time_string.split("T")
        # puts parsed_date

        json_data = {
          "Name"    => milestone_data[:Name],
          "Comment" => milestone_data[:Comment]
        }
        json_data["Email"] = milestone_data[:Email] if milestone_data.key?(:Email)

        milestone = Milestone.new(
          json_data:,
          deadline:          "#{date}T#{time}",
          system_type:       milestone_data[:system_type],
          user_generated:    true,
          milestone_type:    milestone_data[:Type],
          course_project_id: new_project.id
        )

        milestones << milestone
      end

      milestones.each do |m|
        if m.valid?
          m.save
        else
          new_project.destroy
          milestone.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Milestone error: #{attribute} : #{message}")
                errors[:main] << "Milestone error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # Creating assigned facilitators
    facilitators = []
    if no_errors
      project_data[:project_facilitators].each do |user_email|
        facilitator = AssignedFacilitator.new(course_project_id: new_project.id)

        if Staff.exists?(email: user_email)
          facilitator.staff_id = Staff.where(email: user_email).first.id
        elsif Student.exists?(email: user_email)
          facilitator.student_id = Student.where(email: user_email).first.id
        end

        facilitators << facilitator
      end
      facilitators.each do |facilitator|
        if facilitator.valid?
          facilitator.save
          facilitator.reload
        else
          new_project.destroy
          facilitator.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Facilitator error: #{attribute} : #{message}")
                errors[:main] << "Facilitator error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # Creating groups
    if no_errors
      module_students = CourseModule.find_by(code: project_data[:selected_module]).students
      team_size = project_data[:team_size].to_i
      groups = []
      current_group = nil
      team_count = 0

      # Run sorting algorithm for student groups
      students_grouped = []

      if (project_data[:selected_team_allocation_mode] == "random_team_allocation" && !project_data[:teams_from_project_choice]) || project_data[:team_size] == 1
        students_grouped = DatabaseHelper.random_group_allocation(team_size, module_students)
      end

      facilitators_count = facilitators.length
      current_facilitator_index = 0
      if facilitators_count.positive?
        groups_per_facilitator = (students_grouped.length.to_f / facilitators_count).ceil.to_i
      end
      students_grouped.each do |student_subarray|
        # Create a new group for each slice of students
        current_group = Group.new
        team_count += 1
        current_group.name = "Team #{team_count}"
        current_group.course_project_id = new_project.id

        if facilitators_count.positive?
          current_group.assigned_facilitator = facilitators[current_facilitator_index]
          current_facilitator_index += 1 if (team_count % groups_per_facilitator).zero?
        end

        # Add students to the current group
        student_subarray.each do |student|
          current_group.students << student
        end

        # Add the current group to the list of groups
        groups << current_group
      end

      # Save each group using save!
      groups.each do |group|
        if group.valid?
          group.save
        else
          new_project.destroy
          group.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Group error: #{attribute} : #{message}")
                errors[:main] << "Group error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end

    no_errors = errors.all? { |_, v| v.empty? }
    if no_errors
      flash[:notice] = "Project has been created successfully"
      redirect_to action: :index
    else
      render :new
    end
  end

  def update
    session[:project_data][:errors] = {}
    errors = session[:project_data][:errors]

    errors[:top] = []

    project = CourseProject.find(params[:id])

    initial_project_status = project.status

    project_data = session[:project_data]

    if project.status == 'draft'
      @min_date = "#{DateTime.now.strftime('%Y-%m-%dT%H:%M')}"
    else
      @min_date = DateTime.parse(project.created_at.to_s).strftime('%Y-%m-%dT%H:%M')
    end

    # Load in Status to change to if its included in parameters
    if params.key?(:status)
      if CourseProject.statuses.include?(params[:status])
        project_data[:new_status] = params[:status]
        project_data[:selected_status] = params[:status]
      else
        errors[:main] << "Invalid status selected"
      end
    else
      project_data[:new_status] = initial_project_status
    end

    # puts "STATUS CHANGE TO: #{project_data[:new_status]}"

    # Main Data
    project_data[:project_name] = params[:project_name]
    project_data[:selected_module] = params[:module_selection]
    errors[:main] = []
    unless CourseModule.exists?(code: project_data[:selected_module])
      errors[:main] << "The selected module does not exist"
    end

    # Project Choices
    project_data[:teams_from_project_choice] = params.key?(:teams_from_project_choice)
    project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
    errors[:project_choices] = []

    if project_data[:project_choices].size <= 1 && project_data[:project_choices_enabled] && project.status == "draft"
      errors[:project_choices] << "Add at least 2 project choices, or disable this section"
    end

    # Team Config
    project_data[:team_size] = params[:team_size]
    project_data[:selected_team_allocation_mode] = params[:team_allocation_method]
    errors[:team_config] = []

    # Team Preference Form
    project_data[:preferred_teammates] = params[:preferred_teammates]
    project_data[:avoided_teammates] = params[:avoided_teammates]
    errors[:team_pref] = []

    # Timings
    project_data[:project_deadline] = params["milestone_Project Deadline_date"]
    project_data[:teammate_preference_form_deadline] = params["milestone_Teammate Preference Form Deadline_date"]
    project_data[:project_preference_form_deadline] = params["milestone_Project Preference Form Deadline_date"]

    errors[:timings] = []

    project_data[:teams_from_project_choice] = false unless project_data[:project_choices_enabled]

    if (project_data[:project_choices_enabled] && project_data[:teams_from_project_choice]) || project_data[:team_size] == 1
      project_data[:selected_team_allocation_mode] = nil
    end

    project_deadline = nil
    if project_data[:project_deadline].blank?
      errors[:timings] << "Please set project deadline"
    else
      project_deadline = DateTime.parse(project_data[:project_deadline])
    end

    if project_data[:selected_team_allocation_mode] == "preference_form_based" && project_data[:teammate_preference_form_deadline].blank?
      errors[:timings] << "Please set team preference form deadline"
    end
    if project_data[:project_choices_enabled] && project_data[:project_preference_form_deadline].blank?
      errors[:timings] << "Please set project preference form deadline"
    end

    params.each do |key, value|
      # Check if the key starts with "milestone_"
      if key.match?(/^milestone_[^_]+_date$/)
        # Extract the milestone name from the key
        milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]

        # Find the corresponding milestone in the milestones hash and update its "Date" value
        if (milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name })
          milestone[:Date] = value
          unless (defined?(value) && value.present?) || !milestone[:system_type].nil?
            err = "Please make sure all milestones have a date"
            errors[:timings] << err unless errors[:timings].include? err
          end
        end
      end

      next unless key.match?(/^milestone_[^_]+_type$/)

      # Extract the milestone name from the key
      milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]

      # Find the corresponding milestone in the milestones hash and update its "Type" value
      next unless (milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name })
      next unless milestone[:system_type].nil?

      milestone[:Type] = value
      unless defined?(value) && value.present? && Milestone.milestone_types.key?(value)
        err = "Please make sure all milestone types are valid"
        errors[:timings] << err unless errors[:timings].include? err
      end
    end

    # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
    if project_data[:selected_team_allocation_mode] != "preference_form_based" &&
       (milestone = session[:project_data][:project_milestones].find do |m|
         m[:Name] == "Teammate Preference Form Deadline"
       end)
      milestone[:Date] = ""
    end
    if !project_data[:project_choices_enabled] &&
       (milestone = session[:project_data][:project_milestones].find do |m|
         m[:Name] == "Project Preference Form Deadline"
       end)
      milestone[:Date] = ""
    end

    # Check if any milestone dates are set to before the minimum value
    session[:project_data][:project_milestones].each do |m|
      date = m[:Date]
      next unless defined?(date) && date.present?

      project_creation_date = DateTime.parse(project.created_at.to_s)
      datetime = DateTime.parse(date)

      if project.status != "draft" && datetime < project_creation_date
        err = "Milestone dates must be set to later than the project publish date: #{project_creation_date.readable_inspect.split('+').first}"
        errors[:timings] << err unless errors[:timings].include? err

      # if we are in draft, we can only make deadlines later than today or else when it goes out of draft, it will pass instantly
      elsif project.status == "draft" && datetime < DateTime.now
        err = "Milestone dates cannot be set to earlier than the current date"
        errors[:timings] << err unless errors[:timings].include? err
      end
      if datetime > project_deadline
        err = "Milestone dates must be set to earlier than the project deadline"
        errors[:timings] << err unless errors[:timings].include? err
      end
    end

    # If we are changing status to LIVE, we must ensure that the teammate preference form deadline has passed, if its enabled
    if project_data[:new_status] == "live" && project.status != "live"
      pref_form = session[:project_data][:project_milestones].find do |m|
        m[:Name] == "Teammate Preference Form Deadline"
      end
      # puts "CHECKING LIVE STATUS CHANGE REQUIREMENTS"
      # puts pref_form[:Date]
      # puts DateTime.parse(pref_form[:Date])
      # puts DateTime.now
      # puts DateTime.parse(pref_form[:Date]) > DateTime.now
      # puts Time.now

      if pref_form[:Date].present? && DateTime.parse(pref_form[:Date]) > DateTime.now
        errors[:top] << "Cannot set project status to Live: Teammate Preference Form Deadline has not yet passed."
      end
    end

    facilitators_not_found = project_data[:project_facilitators].reject do |email|
      Student.exists?(email:) || Staff.exists?(email:)
    end
    errors[:facilitators_not_found] = facilitators_not_found

    no_errors = errors.all? { |_, v| v.empty? }

    project.course_module_id
    project.team_size
    initial_team_allocation = project.team_allocation
    intially_teams_from_project_choice = project.teams_from_project_choice

    team_allocation_method = project_data[:selected_team_allocation_mode].nil? ? nil : project_data[:selected_team_allocation_mode].to_sym

    # Update Project Details
    if no_errors && project.update(
      course_module:             project.status == "draft" ? CourseModule.find_by(code: project_data[:selected_module]) : project.course_module,
      name:                      project.status == "draft" ? project_data[:project_name] : project.name,
      teams_from_project_choice: project.status == "draft" ? project_data[:teams_from_project_choice] : project.teams_from_project_choice,
      team_size:                 project.status == "draft" ? project_data[:team_size] : project.team_size,
      team_allocation:           project.status == "draft" ? team_allocation_method : project.team_allocation,
      preferred_teammates:       project.status == "draft" ? project_data[:preferred_teammates] : project.preferred_teammates,
      avoided_teammates:         project.status == "draft" ? project_data[:avoided_teammates] : project.avoided_teammates,
      status:                    project_data[:new_status]
    )

      project.reload
      # Reset project's created_at field if it gets published
      if initial_project_status == "draft" && project.status != "draft"
        unless project.update(created_at: DateTime.now)
          project.errors.messages.each do |section, section_errors|
            section_errors.each do |error|
              (errors[section.to_sym] ||= []) << error
            end
          end
        end
      end
    else
      project.errors.messages.each do |section, section_errors|
        section_errors.each do |error|
          (errors[section.to_sym] ||= []) << error
        end
      end
    end

    no_errors = errors.all? { |_, v| v.empty? }

    # destroy all subprojects if project choices disabled,
    # otherwise, destroy all subprojects that have been removed
    # , create any subprojects that have been added, IF status is draft
    if no_errors && project.status == "draft"
      existing_subprojects = project.subprojects
      if project_data[:project_choices_enabled]
        subprojects_to_delete = existing_subprojects.where.not(name: project_data[:project_choices])
        subprojects_to_add = project_data[:project_choices].reject do |choice|
          project.subprojects.pluck(:name).include?(choice)
        end
        subprojects_to_delete.destroy_all

        subprojects = []
        subprojects_to_add.each do |project_choice|
          subproject = Subproject.new(
            name:              project_choice,
            json_data:         "{}",
            course_project_id: project.id
          )
          subprojects << subproject
        end

        subprojects.each do |subproject|
          if subproject.valid?
            subproject.save
          else
            subproject.errors.messages.each do |attribute, messages|
              messages.each do |message|
                unless errors[:timings].include?("Subproject error: #{attribute} : #{message}")
                  errors[:timings] << "Subproject error: #{attribute} : #{message}"
                end
              end
            end
          end
        end
      else
        project.subprojects.destroy_all
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # create any system milestones if they are needed and missing
    # Update existing system milestones
    # destroy any milestones that have been removed
    # create any milestones that have been added
    # update any milestones that have remained
    if no_errors

      existing_milestones = project.milestones.where(user_generated: true)
      # find milestones to destroy: they exist in the db but not in the edit session
      session_milestone_names = project_data[:project_milestones].map { |m| m[:Name] }
      milestones_to_delete = existing_milestones.reject do |m|
        session_milestone_names.include?(m.json_data["Name"])
      end

      # find milestones to create: they exist in the edit session but not the db
      milestones_to_create = project_data[:project_milestones].reject do |m|
        existing_milestones.pluck(:json_data).map { |json_data| json_data["Name"] }.include?(m[:Name])
      end

      # find milestones to update: they exist in the edit session and in the db
      milestones_to_update = existing_milestones.select do |milestone|
        # this additional check is done because to not include system milestones where their date is unset to mark that they shouldnt be pushed
        session_milestone = project_data[:project_milestones].find do |m|
          m[:Name] == milestone.json_data["Name"]
        end
        session_milestone && session_milestone[:Date].present?
      end

      milestones_to_delete.each do |milestone|
        milestone_email = milestone[:json_data]["Email"] if milestone[:json_data].key?("Email")
        unless milestone_email && milestone_email.key?("Sent") && milestone_email["Sent"] == true

          # delete only if the email hasnt been sent
          milestone.destroy
        end
      end

      # Update existing milestones
      milestones_to_update.each do |milestone|
        # get corresponding milestone data
        milestone_name = milestone[:json_data]["Name"]
        milestone_email = milestone[:json_data]["Email"] if milestone[:json_data].key?("Email")
        milestone_data = project_data[:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone.json_data = {
          "Name"    => milestone_name,
          "Comment" => milestone_data[:Comment]
        }

        # puts "UPDATING MILESTONE"
        # if the deadline has passed, or the email has been sent, we can only set the date to the same date or later
        datetime = DateTime.now
        milestone_new_date = DateTime.parse(milestone_data[:Date])
        milestone_current_date = DateTime.parse(milestone.deadline.to_s)
        # puts datetime
        # puts milestone_new_date
        # puts milestone_current_date

        email_sent = milestone_email && milestone_email.key?("Sent") && milestone_email["Sent"] == true

        # puts milestone_new_date < milestone_current_date
        # puts datetime > milestone_current_date

        if milestone_new_date < milestone_current_date
          # puts "New Date Earlier than Current Date"
          if email_sent
            err = "The reminder email for #{milestone_name} has already been sent, and hence you may only set the date to later or equal to its current date, #{milestone_current_date}"
            errors[:timings] << err
            next
          end

          if datetime > milestone_current_date
            # puts "milestone less than current date"
            err = "The deadline for #{milestone_name} has already passed, and hence you may only set the date to later than now"
            errors[:timings] << err
            next
          end
        end

        # dont update the email or type if its already been sent
        if email_sent
          # puts "EMAIL ALREADY SENT"
          milestone.json_data["Email"] = milestone_email if milestone_email
        else
          milestone.json_data["Email"] = milestone_data["Email"] if milestone_data.key?("Email")
          # puts "UPDATING EMAIL"
          milestone.milestone_type = milestone_data[:Type]
        end
        date_time_string = milestone_data[:Date]
        date, time = date_time_string.split("T")
        milestone.deadline = "#{date}T#{time}"

        if milestone.valid?
          milestone.save
        else
          milestone.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Milestone error: #{attribute} : #{message}")
                errors[:main] << "Milestone error: #{attribute} : #{message}"
              end
            end
          end
        end
      end

      # Create additional milestones
      create_milestones_models = []
      milestones_to_create.each do |milestone_data|
        date_time_string = milestone_data[:Date]
        next if date_time_string.blank?

        date, time = date_time_string.split("T")

        # puts "CREATING MILESTONE OF DATE: #{DateTime.parse(date_time_string)}"

        json_data = {
          "Name"    => milestone_data[:Name],
          "Comment" => milestone_data[:Comment]
        }
        json_data["Email"] = milestone_data[:Email] if milestone_data.key?(:Email)

        milestone = Milestone.new(
          json_data:,
          deadline:          "#{date}T#{time}",
          system_type:       milestone_data[:system_type],
          user_generated:    true,
          milestone_type:    milestone_data[:Type],
          course_project_id: project.id
        )

        create_milestones_models << milestone
      end

      milestones = milestones_to_update + create_milestones_models

      milestones.each do |m|
        if m.valid?
          m.save
        else
          milestone.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Milestone error: #{attribute} : #{message}")
                errors[:main] << "Milestone error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # Destroy all assigned facilitators that have been removed
    # Create any assigned facilitators that have been added
    if no_errors
      existing_facilitators = project.assigned_facilitators
      facilitators_to_delete = existing_facilitators.reject do |facilitator|
        project_data[:project_facilitators].include?(facilitator.get_email)
      end
      existing_fac_emails = existing_facilitators.filter_map(&:get_email)
      facilititators_to_add = project_data[:project_facilitators].reject do |facilitator|
        existing_fac_emails.include?(facilitator)
      end

      facilitators_to_delete.each(&:destroy)

      facilitators = []
      facilititators_to_add.each do |user_email|
        facilitator = AssignedFacilitator.new(course_project_id: project.id)

        if Staff.exists?(email: user_email)
          facilitator.staff_id = Staff.where(email: user_email).first.id
        elsif Student.exists?(email: user_email)
          facilitator.student_id = Student.where(email: user_email).first.id
        end

        facilitators << facilitator
      end
      facilitators.each do |facilitator|
        if facilitator.valid?
          facilitator.save
        else
          facilitator.errors.messages.each do |attribute, messages|
            messages.each do |message|
              unless errors[:main].include?("Facilitator error: #{attribute} : #{message}")
                errors[:main] << "Facilitator error: #{attribute} : #{message}"
              end
            end
          end
        end
      end
    end
    no_errors = errors.all? { |_, v| v.empty? }

    # delete groups if they exist if:
    # teams_from_project_choice toggled ON
    # or team allocation mode changed from random to non random
    if no_errors &&
       (project.teams_from_project_choice && !intially_teams_from_project_choice) ||
       (project.team_allocation != initial_team_allocation && project.team_allocation != "random_team_allocation")
      project.groups&.destroy_all
    end

    if no_errors
      if initial_project_status == "draft" && project.status != "draft"
        flash[:notice] = "Project has been published"
      else
        flash[:notice] = "Project has been updated successfully"
      end
      redirect_to project_path(id: project.id)
    else
      render :edit
    end
  end

  def show
    if current_user.is_staff?
      # staff version of viewing one project
      redirect_to project_teams_path(project_id: params[:id])
    else

      # Get independent project information
      @current_project = CourseProject.find(params[:id])
      linked_module = @current_project.course_module
      @proj_name = "#{linked_module.code} #{linked_module.name} - #{@current_project.name}"
      @lead_email = linked_module.staff.email
      @current_group = current_user.student.groups.find_by(course_project_id: params[:id])
      @chat_messages = @current_group.events.where(event_type: :chat).order(created_at: :asc) unless @current_group.nil?

      # Get ordered milestones + deadlines
      @milestones = []
      @current_project.milestones.where(user_generated: true).order("deadline").each do |milestone|
        case milestone.system_type
        when "project_completion_deadline"
          @deadline = "#{milestone.deadline.strftime('%d/%m/%y')} - #{milestone.json_data['Comment']}"
        when "teammate_preference_deadline"
          @pref_form = milestone
          @milestones << "#{milestone.json_data['Name']}: #{milestone.deadline.strftime('%d/%m/%y')} - #{milestone.json_data['Comment']}"
        when "project_preference_deadline"
          @proj_choices_form = milestone
          @milestones << "#{milestone.json_data['Name']}: #{milestone.deadline.strftime('%d/%m/%y')} - #{milestone.json_data['Comment']}"
        else
          @milestones << "#{milestone.json_data['Name']}: #{milestone.deadline.strftime('%d/%m/%y')} - #{milestone.json_data['Comment']}"
        end
      end

      # Preference Form
      @show_pref_form = false

      if @current_project.team_allocation == "preference_form_based" && !@pref_form.nil?
        @yes_mates = @current_project.preferred_teammates.to_i
        @no_mates = @current_project.avoided_teammates.to_i

        # Should the preference form be shown
        first_response = MilestoneResponse.where(milestone_id: @pref_form.id,
                                                 student_id:   current_user.student.id).empty?
        @show_pref_form = (@current_project.status == "preparation") && first_response
      end

      # Project Choices Form
      @show_proj_form = false

      unless @proj_choices_form.nil?

        @choices = @current_project.subprojects.pluck("name")
        # Should the project choice form be shown
        first_response = MilestoneResponse.where(milestone_id: @proj_choices_form.id,
                                                 student_id:   current_user.student.id).empty?
        in_group = current_user.student.groups.find_by(course_project: @current_project).present?
        no_subproject = false
        if in_group
          no_subproject = current_user.student.groups.find_by(course_project: @current_project).subproject.nil?
        end

        if @current_project.teams_from_project_choice
          @show_proj_form = (@current_project.status == "preparation") && first_response
        else
          @show_proj_form = (@current_project.status == "live") && first_response && in_group && no_subproject
        end
      end

      # Get group-dependent project information
      if current_user.student.groups.find_by(course_project: @current_project).nil?
        @show_group_information = false
      else
        @show_group_information = true

        group = current_user.student.groups.find_by(course_project: @current_project)
        @group_name = group.name

        # Get subproject information
        if @current_project.subprojects.empty?
          @subproject = nil
        else
          unless group.subproject.nil?
            @subproject = group.subproject
          else
            @subproject = "No Subproject Currently Assigned"
          end
        end

        # Get team information
        @team_names = []
        @team_emails = []
        group.students.each do |teammate|
          @team_names << "#{teammate.preferred_name} #{teammate.surname}"
          @team_emails << teammate.email
        end

        # Get facilitator information
        if group.assigned_facilitator_id.nil?
          @facilitator_email = "Facilitators have not been assigned yet"
        else
          facilitator = AssignedFacilitator.find(group.assigned_facilitator_id)
          @facilitator_email = if facilitator.staff_id.nil?
            Student.find(facilitator.student_id).email
          else
            Staff.find(facilitator.staff_id).email
          end
        end
      end

      # Get mark scheme if created
      @mark_scheme = Milestone.select do |m|
        m.system_type == "marking_deadline" &&
          m.course_project_id == @current_project.id
      end.first

      # Render view
      render "show_student"
    end
  end

  def search_student_name
    query = params[:query]
    project = CourseProject.find(params[:project_id])

    query_parts = query.split(" ")
    preferred_name = query_parts[0]
    surname = query_parts[1]

    @results = project.course_module.students.where(
      "(preferred_name LIKE :preferred_name AND surname LIKE :surname) OR (preferred_name LIKE :surname AND surname LIKE :preferred_name)", preferred_name: "%#{preferred_name}%", surname: "%#{surname}%"
    ).limit(8).distinct
    render json: @results.map { |student| "#{student.preferred_name} #{student.surname}" }
  end

  def send_chat_message
    @current_group = Group.find(params[:group_id])

    return if @current_group.nil?

    @chat_messages = @current_group.events.where(event_type: :chat).order(created_at: :asc)

    json_data = {
      content:   params[:message],
      author:    params[:author],
      timestamp: Time.zone.now
    }

    if current_user.is_staff?
      @chat_message = Event.new(event_type: :chat, json_data:, group_id: @current_group.id,
                                staff_id: current_user.staff.id)
    elsif current_user.is_student?
      @chat_message = Event.new(event_type: :chat, json_data:, group_id: @current_group.id,
                                student_id: current_user.student.id)
    end

    return unless @chat_message.save
    return unless request.xhr?

    respond_to(&:js)
  end

  def remake_teams
    project = CourseProject.find(params[:id])

    errors = {}
    errors[:main] = {}

    project.groups&.destroy_all

    CourseModule.find(project.course_module_id)
    module_students = CourseModule.find(project.course_module_id).students
    logger.debug("!!!!!!!!!!!!!!!!!! #{project.team_allocation}")
    team_size = project.team_size.to_i
    groups = []
    current_group = nil
    team_count = 0

    if project.teams_from_project_choice
      proj_choice_milestone = Milestone.find_by(system_type:       :project_preference_deadline,
                                                course_project_id: project.id)

      students_grouped = DatabaseHelper.project_choices_group_allocation(team_size, module_students,
                                                                         proj_choice_milestone)
    elsif project.team_allocation == "preference_form_based"
      pref_form_milestone = Milestone.find_by(system_type: :teammate_preference_deadline, course_project_id: project.id)

      students_grouped = DatabaseHelper.preference_form_group_allocation(team_size, module_students,
                                                                         pref_form_milestone)
    elsif project.team_allocation == "random_team_allocation"
      students_grouped = DatabaseHelper.random_with_heuristics_allocation(team_size, module_students)
    end

    project.reload
    facilitators = project.assigned_facilitators
    facilitators_count = facilitators.length
    current_facilitator_index = 0
    if facilitators_count.positive?
      groups_per_facilitator = (students_grouped.length.to_f / facilitators_count).ceil.to_i
    end
    students_grouped.each do |student_subarray|
      # Create a new group for each slice of students
      current_group = Group.new
      team_count += 1
      current_group.name = "Team #{team_count}"
      current_group.course_project_id = project.id

      if facilitators_count.positive?
        current_group.assigned_facilitator = facilitators[current_facilitator_index]
        current_facilitator_index += 1 if (team_count % groups_per_facilitator).zero?
      end

      # Add students to the current group
      student_subarray.each do |student|
        current_group.students << student
      end

      # Add the current group to the list of groups
      groups << current_group
    end

    # Save each group using save!
    groups.each do |group|
      if group.valid?
        group.save
      else
        group.errors.messages.each do |attribute, messages|
          messages.each do |message|
            unless errors[:main].include?("Group error: #{attribute} : #{message}")
              errors[:main] << "Group error: #{attribute} : #{message}"
            end
          end
        end
      end
    end
    redirect_to project_teams_path(project_id: project.id)
  end


  def delete
    project = CourseProject.find(params[:id])
    if project.destroy
      flash[:notice] = "Project successfully deleted"
      redirect_to projects_path
    else
      flash[:error] = "An error occurred"
    end
  end

  private
  def rerender_edit_or_new
    if session[:context] && session[:context] == "new"
      render :new
    elsif session[:context] && session[:context] == "edit"
      render :edit
    else
      flash[:alert] = "Error re-rendering page"
      redirect_back fallback_location: root_path
    end
  end
end
