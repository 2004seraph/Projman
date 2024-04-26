require 'json'

# INTAKE/OUTTAKE: How its stored in the model
# Session Fromat: How its stored in the controller session hash

# Project Choices INTAKE/OUTTAKE:
# JSON: { "1": "Project Choice A"
#         "2": "Project Choice B"}
# Project choices Session Format:
# ["Project Choice A", "Project Choice B"]

# Project Milestones INTAKE/OUTTAKE:
# New Milestone Model
# Project Milestones Session Format:
# [ {"Name": "Technical Review", "Date": "dd/mm/yyyy"},
#   {"Name": "Peer Review", "Date: "dd/mm/yyyy"}]

class CourseProjectController < ApplicationController

    load_and_authorize_resource

    skip_before_action :verify_authenticity_token, only: [
        :remove_project_choice,
        :clear_facilitator_selection,
        :toggle_project_choices,
        :remove_project_milestone,
        :remove_from_facilitator_selection,
        :remove_facilitator,
        :create
    ]

    def index
        if current_user.is_staff?
            @projects = current_user.staff.course_projects
            @course_modules = current_user.staff.course_modules.length
            render 'index_module_leader'
        else
            @projects = current_user.student.course_projects
            render 'index_student'
        end
    end

    def new
        staff_id = Staff.where(email: current_user.email).first

        modules_hash = CourseModule.all.where(staff_id: staff_id).order(:code).pluck(:code, :name).to_h
        # if a staff is not a module lead for any module, do not show them the new page
        if modules_hash.length == 0
            flash[:alert] = "You are not part of any modules. Please contact an admin if this is in error."
            redirect_to session[:redirect_url]  # previous page, or `action: :index` if you prefer
        end

        project_allocation_modes_hash = CourseProject.project_allocations
        team_allocation_modes_hash = CourseProject.team_allocations
        milestone_types_hash = Milestone.milestone_types

        session[:project_data] = {
            errors: {},
            modules_hash: modules_hash,
            project_allocation_modes_hash: project_allocation_modes_hash,
            team_allocation_modes_hash: team_allocation_modes_hash,
            milestone_types_hash: milestone_types_hash,

            selected_module: "",
            project_name: "",
            selected_project_allocation_mode: "",
            project_choices: [],
            team_size: 4,
            selected_team_allocation_mode: "",
            preferred_teammates: 2,
            avoided_teammates: 2,
            project_milestones: [{"Name": "Project Deadline", "Date": "", "Type": "team", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""},
                                {"Name": "Project Preference Form Deadline", "Date": "", "Type": "team", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""}],
            project_facilitators: [],

            facilitator_selection: [],
            project_choices_enabled: true
        }
    end


    def edit
        project_id = params[:id]
        project = CourseProject.find(project_id)
        staff_id = Staff.where(email: current_user.email).first

        modules_hash = CourseModule.all.where(staff_id: staff_id).order(:code).pluck(:code, :name).to_h
        # if a staff is not a module lead for any module, do not show them the new page
        if modules_hash.length == 0
            flash[:alert] = "You are not part of any modules. Please contact an admin if this is in error."
            redirect_to session[:redirect_url]  # previous page, or `action: :index` if you prefer
        end

        project_allocation_modes_hash = CourseProject.project_allocations
        team_allocation_modes_hash = CourseProject.team_allocations
        milestone_types_hash = Milestone.milestone_types

        project_choices = project.subprojects.pluck(:name)
        project_milestones = project.milestones.where(user_generated: true)
        project_assigned_facilitators = project.assigned_facilitators
        project_facilitators = []
        project_assigned_facilitators.each do |facilitator|
            if facilitator[:staff_id].present?
                project_facilitators << Staff.find(facilitator[:staff_id])[:email]
            end
            if facilitator[:student_id].present?
                project_facilitators << Student.find(facilitator[:student_id])[:email]
            end
        end
        project_milestones_parsed = []

        # TODO: Also, ignore any milestones on the project that arent created by a user

        project_milestones.each do |milestone_data|
            date_string = milestone_data[:deadline].to_s
            parsed_date = Date.strptime(date_string, "%Y-%m-%d").strftime("%d/%m/%Y")
            milestone_type = milestone_data[:milestone_type]
            json_data = milestone_data[:json_data]
            milestone = {"Name": json_data["Name"], "Date": parsed_date, "Type": milestone_type, "isDeadline": json_data["isDeadline"], "Email": json_data["Email"], "Comment": json_data["Comment"]}
            project_milestones_parsed << milestone
        end
        # add preference form milestones, if missing. (they arent pushed if they dont apply at the time)
        project_deadline = project_milestones_parsed.find { |m| m[:Name] == "Project Deadline" }[:Date]
        team_pref_deadline = ""
        proj_pref_deadline = ""
        if milestone = project_milestones_parsed.find { |m| m[:Name] == "Teammate Preference Form Deadline" }
            team_pref_deadline = milestone[:Date]
        else
            project_milestones_parsed << {"Name": "Teammate Preference Form Deadline", "Date": "", "Type": "student", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""}
        end
        if milestone = project_milestones_parsed.find { |m| m[:Name] == "Project Preference Form Deadline" }
            proj_pref_deadline = milestone[:Date]
        else
            project_milestones_parsed << {"Name": "Project Preference Form Deadline", "Date": "", "Type": "team", "isDeadline": true, "Email": {"Content": "", "Advance": ""}, "Comment": ""}
        end

        session[:project_data] = {
            errors: {},
            modules_hash: modules_hash,
            project_allocation_modes_hash: project_allocation_modes_hash,
            team_allocation_modes_hash: team_allocation_modes_hash,
            milestone_types_hash: milestone_types_hash,

            selected_module: CourseModule.find(project[:course_module_id])[:code],
            project_name: project[:name],
            selected_project_allocation_mode: project[:project_allocation],
            project_choices: project_choices,
            team_size: project[:team_size],
            selected_team_allocation_mode: project[:team_allocation],
            preferred_teammates: project[:preferred_teammates],
            avoided_teammates: project[:avoided_teammates],
            project_milestones: project_milestones_parsed,
            project_deadline: project_deadline, 
            teammate_preference_form_deadline: team_pref_deadline,
            project_preference_form_deadline: proj_pref_deadline,

            project_facilitators: project_facilitators,

            facilitator_selection: [],
            project_choices_enabled: project_choices.length > 0
        }
    end

    # POST
    def add_project_choice
        @project_choice_name = params[:project_choice_name]
        session[:project_data][:project_choices] << @project_choice_name

        # If done via AJAX (JavaScript enabled), dynamically add
        if request.xhr?
            respond_to do |format|
                format.js
            end

        # Otherwise re-render :new
        else
            render :new
        end
    end

    def remove_project_choice
        @project_choice_name = params[:item_text].strip
        session[:project_data][:project_choices].delete(@project_choice_name)
        if request.xhr?
        else
            render :new
        end
    end

    def add_project_milestone
        @project_milestone_name = params[:project_milestone_name]
        @project_milestone_name.gsub('_', ' ')
        project_milestone_unique = false
        unless session[:project_data][:project_milestones].any? { |milestone| milestone[:Name] == @project_milestone_name }
            session[:project_data][:project_milestones] << {"Name": @project_milestone_name, "Date": "", "Type": "", "isDeadline": false, "Email": {"Content": "", "Advance": ""}, "Comment": ""}
            project_milestone_unique = true
        end
        if request.xhr?
            respond_to do |format|
                if project_milestone_unique
                    format.js
                end
            end
        else
            render :new
        end
    end

    def remove_project_milestone
        @project_milestone_name = params[:item_text].strip.match(/^milestone_([^_]+)/)[1]
        filtered_milestones = session[:project_data][:project_milestones].reject do |milestone|
            milestone[:Name] == @project_milestone_name
        end
        session[:project_data][:project_milestones] = filtered_milestones

        if request.xhr?
            respond_to do |format|
                format.js
            end
        else
            render :new
        end
    end

    def clear_facilitator_selection
        session[:project_data][:facilitator_selection] = []
    end

    def add_to_facilitator_selection
        @facilitator_email = params[:project_facilitator_name]
        if @facilitator_email.present?
            session[:project_data][:facilitator_selection] << @facilitator_email
        end
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
        session[:project_data][:facilitator_selection].delete(@facilitator_email)
    end

    def add_facilitator_selection
        @facilitators_added = []
        session[:project_data][:facilitator_selection].each do |facilitator|
            unless session[:project_data][:project_facilitators].include?(facilitator)
              session[:project_data][:project_facilitators] << facilitator
              @facilitators_added << facilitator
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

    def remove_facilitator
        @facilitator_email = params[:item_text]
        session[:project_data][:project_facilitators].delete(@facilitator_email)
    end

    def search_facilitators_student
        query = params[:query]
        puts params
        @results = Student.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def search_facilitators_staff
        query = params[:query]
        @results = Staff.where("email LIKE ?", "%#{query}%").limit(8).distinct
        render json: @results.pluck(:email)
    end

    def get_milestone_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        respond_to do |format|
            format.json { render json: milestone }
        end
    end

    def set_milestone_email_data
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone[:Email][:Content] = params[:milestone_email_content]
        milestone[:Email][:Advance] = params[:milestone_email_advance]
    end

    def set_milestone_comment
        milestone_name = params[:milestone_name].split('_').drop(1).join('_')
        milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
        milestone[:Comment] = params[:milestone_comment]
    end

    def create

        session[:project_data][:errors] = {}
        errors = session[:project_data][:errors]

        project_data = session[:project_data]

        # Main Data
        project_data[:project_name] = params[:project_name]
        project_data[:selected_module] = params[:module_selection]
        errors[:main] = []
        unless CourseModule.exists?(code: project_data[:selected_module])
            errors[:main] << "The selected module does not exist"
        end

        # Project Choices
        project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
        project_data[:selected_project_allocation_mode] = params[:project_allocation_method]
        errors[:project_choices] = []

        if !project_data[:project_choices].present? && project_data[:project_choices_enabled]
            errors[:project_choices] << "Add some project choices, or disable this section"
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

        unless project_data[:project_deadline].present?
            errors[:timings] << "Please set project deadline"
        end
        if project_data[:selected_team_allocation_mode] != "random_team_allocation" && !project_data[:teammate_preference_form_deadline].present?
            errors[:timings] << "Please set team preference form deadline"
        end
        if (project_data[:project_choices_enabled] && project_data[:selected_project_allocation_mode] != "random_project_allocation") && !project_data[:project_preference_form_deadline].present?
            errors[:timings] << "Please set project preference form deadline"
        end

        params.each do |key, value|
            # Check if the key starts with "milestone_"
            if key.match?(/^milestone_[^_]+_date$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Date" value
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    milestone[:Date] = value
                    unless (defined?(value) && value.present?) || milestone[:isDeadline]
                        err = "Please make sure all milestones have a date"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end

            if key.match?(/^milestone_[^_]+_type$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Type" value
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    next if milestone[:isDeadline]
                    milestone[:Type] = value
                    unless defined?(value) && value.present? && Milestone.milestone_types.key?(value)
                        err = "Please make sure all milestone types are valid"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end
        end

        facilitators_not_found = project_data[:project_facilitators].reject do |email|
            Student.exists?(email: email) || Staff.exists?(email: email)
        end
        errors[:facilitators_not_found] = facilitators_not_found

        no_errors = errors.all? { |_, v| v.empty? }
        # Creating Project Model
        new_project = CourseProject.new(
            course_module: CourseModule.find_by(code: project_data[:selected_module]),
            name: project_data[:project_name],
            # project_choices_json: project_data[:project_choices_enabled] ? project_data[:project_choices].to_json : "[]",
            project_allocation: project_data[:selected_project_allocation_mode].to_sym,
            team_size: project_data[:team_size],
            team_allocation: project_data[:selected_team_allocation_mode].to_sym,
            preferred_teammates:  project_data[:preferred_teammates],
            avoided_teammates: project_data[:avoided_teammates],
            status: :draft
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
                        name: project_choice,
                        json_data: "{}",
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

        # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
        if no_errors
            if project_data[:selected_team_allocation_mode] == "random_team_allocation"
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == "Teammate Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
            if !project_data[:project_choices_enabled] || project_data[:selected_project_allocation_mode] == "random_project_allocation"
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == "Project Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
        end

        # Creating associated milestones
        if no_errors
            milestones = []
            project_data[:project_milestones].each do |milestone_data|

                # dd/mm/yyyy to yyyy-mm-dd
                date_string = milestone_data[:Date]
                # This did a funny where sometimes the format was recieved as m/d/y, hasnt happened again since what should have fixed it
                # puts date_string
                next if !date_string.present?   #dont push the milestone if its not got a set date
                parsed_date = Date.strptime(date_string, "%d/%m/%Y").strftime("%Y-%m-%d")
                # puts parsed_date

                # check which system type of milestone this is, if it is supposed to be
                system_type = nil
                if milestone_data[:Name] == "Project Deadline"
                    system_type = "project_deadline"
                elsif milestone_data[:Name] == "Project Preference Form Deadline"
                    system_type = "project_preference_deadline"
                elsif milestone_data[:Name] == "Teammate Preference Form Deadline"
                    system_type = "teammate_preference_deadline"
                end

                json_data = {
                    "Name" => milestone_data[:Name],
                    "isDeadline" => milestone_data[:isDeadline],
                    "Email" => milestone_data[:Email],
                    "Comment" => milestone_data[:Comment]
                }

                milestone = Milestone.new(
                    json_data: json_data,
                    deadline: parsed_date,
                    system_type: system_type,
                    user_generated: true,
                    milestone_type: milestone_data[:Type],
                    course_project_id: new_project.id
                )

                milestones << milestone
            end

            milestones.each do |milestone|
                if milestone.valid?
                    milestone.save
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

        #Creating assigned facilitators
        if no_errors
            facilitators = []
            project_data[:project_facilitators].each do |user_email|

                facilitator = AssignedFacilitator.new(course_project_id: new_project.id);

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

        # Creating groups (currently just puts everyone in groups of X size, no randomness or preference)
        if no_errors
            module_students = CourseModule.find_by(code: project_data[:selected_module]).students
            team_size = project_data[:team_size].to_i
            groups = []
            current_group = nil
            team_count = 0

            module_students.each_slice(team_size) do |students_slice|

                # Create a new group for each slice of students
                current_group = Group.new
                team_count += 1
                current_group.name = "Team " + team_count.to_s
                current_group.course_project_id = new_project.id

                # Add students to the current group
                students_slice.each do |student|
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

        project_data = session[:project_data]

        # Main Data
        project_data[:project_name] = params[:project_name]
        project_data[:selected_module] = params[:module_selection]
        errors[:main] = []
        unless CourseModule.exists?(code: project_data[:selected_module])
            errors[:main] << "The selected module does not exist"
        end

        # Project Choices
        project_data[:project_choices_enabled] = params.key?(:project_choices_enable)
        project_data[:selected_project_allocation_mode] = params[:project_allocation_method]
        errors[:project_choices] = []

        if !project_data[:project_choices].present? && project_data[:project_choices_enabled]
            errors[:project_choices] << "Add some project choices, or disable this section"
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

        unless project_data[:project_deadline].present?
            errors[:timings] << "Please set project deadline"
        end
        if project_data[:selected_team_allocation_mode] != "random_team_allocation" && !project_data[:teammate_preference_form_deadline].present?
            errors[:timings] << "Please set team preference form deadline"
        end
        if (project_data[:project_choices_enabled] && project_data[:selected_project_allocation_mode] != "random_project_allocation") && !project_data[:project_preference_form_deadline].present?
            errors[:timings] << "Please set project preference form deadline"
        end

        params.each do |key, value|
            # Check if the key starts with "milestone_"
            if key.match?(/^milestone_[^_]+_date$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_date$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Date" value
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    milestone[:Date] = value
                    unless (defined?(value) && value.present?) || milestone[:isDeadline]
                        err = "Please make sure all milestones have a date"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end

            if key.match?(/^milestone_[^_]+_type$/)
                # Extract the milestone name from the key
                milestone_name = key.match(/^milestone_([^_]+)_type$/)[1]

                # Find the corresponding milestone in the milestones hash and update its "Type" value
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == milestone_name }
                    next if milestone[:isDeadline]
                    milestone[:Type] = value
                    unless defined?(value) && value.present? && Milestone.milestone_types.key?(value)
                        err = "Please make sure all milestone types are valid"
                        unless errors[:timings].include? err
                            errors[:timings] << err
                        end
                    end
                end
            end
        end

        facilitators_not_found = project_data[:project_facilitators].reject do |email|
            Student.exists?(email: email) || Staff.exists?(email: email)
        end
        errors[:facilitators_not_found] = facilitators_not_found

        no_errors = errors.all? { |_, v| v.empty? }

        project = CourseProject.find(params[:id])
        # Update Project Details
        if project.update(
            course_module: CourseModule.find_by(code: project_data[:selected_module]),
            name: project_data[:project_name],
            project_allocation: project_data[:selected_project_allocation_mode].to_sym,
            team_size: project_data[:team_size],
            team_allocation: project_data[:selected_team_allocation_mode].to_sym,
            preferred_teammates:  project_data[:preferred_teammates],
            avoided_teammates: project_data[:avoided_teammates],
            status: :draft)
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
        # , create any subprojects that have been added
        if no_errors
            existing_subprojects = project.subprojects
            unless project_data[:project_choices_enabled]
                project.subprojects.destroy_all
            else
                subprojects_to_delete = existing_subprojects.where.not(name: project_data[:project_choices])
                subprojects_to_add = project_data[:project_choices].reject do |choice|
                    project.subprojects.pluck(:name).include?(choice)
                end
                subprojects_to_delete.destroy_all

                subprojects = []
                subprojects_to_add.each do |project_choice|
                    subproject = Subproject.new(
                        name: project_choice,
                        json_data: "{}",
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
            end
        end
        no_errors = errors.all? { |_, v| v.empty? }

        # For Preference Form milestones, clear their dates so they are not pushed IF they dont apply to the project
        if no_errors
            if project_data[:selected_team_allocation_mode] == "random_team_allocation"
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == "Teammate Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
            if !project_data[:project_choices_enabled] || project_data[:selected_project_allocation_mode] == "random_project_allocation"
                if milestone = session[:project_data][:project_milestones].find { |m| m[:Name] == "Project Preference Form Deadline"}
                    milestone[:Date] = ""
                end
            end
        end

        
        # create any system milestones if they are needed and missing
        # Update existing system milestones
        # destroy any milestones that have been removed
        # create any milestones that have been added
        # update any milestones that have remained
        if no_errors

            existing_milestones = project.milestones.where(user_generated: true)
            # find milestones to destroy: they exist in the db but not in the edit session
            session_milestone_names = project_data[:project_milestones].map { |milestone| milestone[:Name] }
            milestones_to_delete = existing_milestones.reject do |milestone|
                session_milestone_names.include?(milestone.json_data["Name"])
            end

            # find milestones to create: they exist in the edit session but not the db
            milestones_to_create = project_data[:project_milestones].reject do |milestone|
                existing_milestones.pluck(:json_data).map{|json_data| json_data["Name"]}.include?(milestone[:Name])
            end

            # find milestones to update: they exist in the edit session and in the db
            milestones_to_update = existing_milestones.select do |milestone|
                session_milestone_names.include?(milestone.json_data["Name"])
            end

            milestones_to_delete.each(&:destroy)

            # Update existing milestones
            milestones_to_update.each do |milestone|
                # get corresponding milestone data
                milestone_name = milestone[:json_data]["Name"]
                milestone_data = project_data[:project_milestones].find { |m| m[:Name] == milestone_name}
                milestone.json_data = {
                    "Name" => milestone_name,
                    "isDeadline" => milestone_data[:isDeadline],
                    "Email" => milestone_data[:Email],
                    "Comment" => milestone_data[:Comment]
                }
                date_string = milestone_data[:Date]
                parsed_date = Date.strptime(date_string, "%d/%m/%Y").strftime("%Y-%m-%d")
                milestone.deadline = parsed_date
                milestone.milestone_type = milestone_data[:Type]
            end

            milestones_to_update.each do |milestone|
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
                date_string = milestone_data[:Date]
                next if !date_string.present?
                parsed_date = Date.strptime(date_string, "%d/%m/%Y").strftime("%Y-%m-%d")

                # check which system type of milestone this is, if it is supposed to be
                system_type = nil
                if milestone_data[:Name] == "Project Deadline"
                    system_type = "project_deadline"
                elsif milestone_data[:Name] == "Project Preference Form Deadline"
                    system_type = "project_preference_deadline"
                elsif milestone_data[:Name] == "Teammate Preference Form Deadline"
                    system_type = "teammate_preference_deadline"
                end

                json_data = {
                    "Name" => milestone_data[:Name],
                    "isDeadline" => milestone_data[:isDeadline],
                    "Email" => milestone_data[:Email],
                    "Comment" => milestone_data[:Comment]
                }

                milestone = Milestone.new(
                    json_data: json_data,
                    deadline: parsed_date,
                    system_type: system_type,
                    user_generated: true,
                    milestone_type: milestone_data[:Type],
                    course_project_id: project.id
                )

                create_milestones_models << milestone
            end

            milestones = milestones_to_update + create_milestones_models

            milestones.each do |milestone|
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
        end
        no_errors = errors.all? { |_, v| v.empty? }

        # Destroy all assigned facilitators that have been removed
        # Create any assigned facilitators that have been added
        if no_errors
            existing_facilitators = project.assigned_facilitators
            facilitators_to_delete = existing_facilitators.reject do |facilitator|
                project_data[:project_facilitators].include?(facilitator.get_email)
            end
            existing_fac_emails = existing_facilitators.map { |facilitator| facilitator.get_email }.compact
            facilititators_to_add = project_data[:project_facilitators].reject do |facilitator|
                existing_fac_emails.include?(facilitator)
            end

            facilitators_to_delete.each(&:destroy)

            facilitators = []
            facilititators_to_add.each do |user_email|

                facilitator = AssignedFacilitator.new(course_project_id: project.id);

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

        # remake groups if module changes
        # remake groups if team size changes, and set to random
        # remake groups if mode is changed from not random to random

        if no_errors
            flash[:notice] = "Project has been updated successfully"
            redirect_to action: :edit
        else
            render :edit
        end
    end

    def show
        if current_user.is_staff?
            # staff version of viewing one project
        else

            #Get independent project information (project name, leader, milestones, preference form)
            @current_project = CourseProject.find(params[:id])
            linked_module = @current_project.course_module
            @proj_name = linked_module.code+' '+linked_module.name+' - '+@current_project.name
            @lead_email = linked_module.staff.email

            #Get ordered milestones + deadlines
            @milestones = []
            @current_project.milestones.order('deadline').each do |milestone|
                if milestone.json_data['Name'] == 'Project Deadline'
                    @deadline = milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                elsif milestone.json_data['Name'] == 'Teammate Preference Form Deadline'
                    @pref_form = milestone
                    @milestones << milestone.json_data['Name']+': '+milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                elsif milestone.json_data['Name'] == 'Project Preference Form Deadline'
                    @proj_choices_form = milestone
                    @milestones << milestone.json_data['Name']+': '+milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                else
                    @milestones << milestone.json_data['Name']+': '+milestone.deadline.strftime('%d/%m/%y')+' - '+milestone.json_data['Comment']
                end
            end

            #Preference Form
            @show_pref_form = false

            if @current_project.team_allocation == 'preference_form_based'
                @yes_mates = @current_project.preferred_teammates.to_i
                @no_mates = @current_project.avoided_teammates.to_i

                #Should the preference form be shown
                first_response = MilestoneResponse.where(milestone_id: @pref_form.id, student_id: current_user.student.id).empty?
                @show_pref_form = (@current_project.status == 'student_preference') && first_response
            end

            #Get group-dependent project information
            if current_user.student.groups.find_by(course_project_id: @current_project.id).nil?
                @show_group_information = false
            else
                @show_group_information = true
                group = current_user.student.groups.find_by(course_project_id: @current_project.id)
                @group_name = group.name

                #Project Choices Form
                @show_proj_form = false

                unless @current_project.project_allocation == 'random_project_allocation'
                    @choices = @current_project.subprojects.pluck('name')

                    #Should the project choice form be shown
                    personal_response = MilestoneResponse.where(milestone_id: @proj_choices_form.id, student_id: current_user.student.id).empty?

                    group_response = true
                    if @current_project.project_allocation == 'single_preference_project_allocation'
                        group.students.each do |teammate|
                            unless MilestoneResponse.where(milestone_id: @proj_choices_form.id, student_id: teammate.id).empty?
                                group_response = false
                            end
                        end
                    end

                    @show_proj_form = (@current_project.status == 'team_preference') && personal_response && group_response

                end

                #Get team information
                @team_names = []
                @team_emails = []
                group.students.each do |teammate|
                    @team_names << teammate.preferred_name+' '+teammate.surname
                    @team_emails << teammate.email
                end

                #Get facilitator information
                unless group.assigned_facilitator_id == nil
                    facilitator = AssignedFacilitator.find(group.assigned_facilitator_id)
                    if facilitator.staff_id == nil
                        @facilitator_email = Student.find(facilitator.student_id).email
                    else
                        @facilitator_email = Staff.find(facilitator.staff_id).email
                    end
                else
                    @facilitator_email = "Facilitators have not been assigned yet"
                end

            end

            #Render view
            render 'show_student'
        end
    end

    def search_student_name
        query = params[:query]
        project = CourseProject.find(params[:project_id])

        query_parts = query.split(" ")
        preferred_name = query_parts[0]
        surname = query_parts[1]

        @results = project.course_module.students.where("(preferred_name LIKE :preferred_name AND surname LIKE :surname) OR (preferred_name LIKE :surname AND surname LIKE :preferred_name)", preferred_name: "%#{preferred_name}%", surname: "%#{surname}%").limit(8).distinct
        render json: @results.map { |student| "#{student.preferred_name} #{student.surname}" }

    end

    def teams

    end
end
