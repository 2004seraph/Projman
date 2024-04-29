

module DatabaseHelper
  PREFIX = "[Database]"
  NOTICE = "#{PREFIX} Notice:"
  WARNING = "#{PREFIX} Warning:"
  ERROR = "#{PREFIX} Error:"

  TITLES = [["Mr"], ["Miss", "Ms", "Mrs"], ["Mx", "Dr", "Prof"]]

  extend self

  def print_validation_errors(model_instance)
    if not model_instance.valid?
      puts "#{ERROR} #{model_instance.class.name} instance is invalid:"
      puts model_instance.errors.full_messages
    else
      puts "#{NOTICE} #{model_instance.class.name} instance is valid"
    end
  end

  # DATA SEEDING

  def create_course_project(
    module_code = "COM3420",
    name = "Test Project",
    status = "draft",
    project_choices = ["Choice 1", "Choice 2"],
    team_size = 4,
    preferred_teammates = 1,
    avoided_teammates = 2,
    team_allocation_mode = "random_team_allocation",
    project_allocation_mode = "team_preference_project_allocation",
    
    project_deadline = DateTime.now + 1.minute,
    project_pref_deadline = DateTime.now + 1.minute,
    team_pref_deadline = DateTime.now + 1.minute,
    milestones = [{"Name": "Milestone 1", "Deadline": DateTime.now + 1.minute, "Email": {"Content": "This is an email", "Advance": 0}, "Comment": "This is a comment", "Type": "team"}],
    facilitators = ["jbala1@sheffield.ac.uk"])
    project = CourseProject.create(
      course_module: CourseModule.find_by(code: module_code),
      name: name,
      project_allocation: project_allocation_mode.to_sym,
      team_size: team_size,
      team_allocation: team_allocation_mode.to_sym,
      preferred_teammates:  preferred_teammates,
      avoided_teammates: avoided_teammates,
      status: status
    )
    DatabaseHelper.print_validation_errors(project)

    project_choices.each do |choice| 
      subproject = Subproject.create(
        name: choice,
        json_data: "{}",
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(subproject)
    end

    project_deadline_json_data = {
      "Name" => "Project Deadline",
      "isDeadline" => true,
      "Comment" => "",
      "Email" => {"Content": "Project Deadline upcoming!", "Advance": 0}
    }
    project_deadline_milestone = Milestone.create(
      json_data: project_deadline_json_data,
      deadline: project_deadline,
      system_type: "project_deadline",
      user_generated: true,
      milestone_type: "team",
      course_project_id: project.id
    )
    DatabaseHelper.print_validation_errors(project_deadline_milestone)

    proj_pref_json_data = {
      "Name" => "Project Deadline",
      "isDeadline" => true,
      "Comment" => "",
      "Email" => {"Content": "Project Deadline upcoming!", "Advance": 0}
    }
    proj_pref_milestone = Milestone.create(
      json_data: proj_pref_json_data,
      deadline: project_pref_deadline,
      system_type: "project_preference_deadline",
      user_generated: true,
      milestone_type: "student",
      course_project_id: project.id
    )
    DatabaseHelper.print_validation_errors(proj_pref_milestone)

    team_pref_json_data = {
      "Name" => "Project Deadline",
      "isDeadline" => true,
      "Comment" => "",
      "Email" => {"Content": "Project Deadline upcoming!", "Advance": 0}
    }
    team_pref_milestone = Milestone.create(
      json_data: team_pref_json_data,
      deadline: DateTime.now + 1.minute,
      system_type: "teammate_preference_deadline",
      user_generated: true,
      milestone_type: "student",
      course_project_id: project.id
    )
    DatabaseHelper.print_validation_errors(team_pref_milestone)

    milestones.each do |milestone| 
      json_data = {
        "Name" => milestone[:Name],
        "isDeadline" => false,
        "Comment" => milestone[:Comment],
      }
      json_data["Email"] = milestone[:Email] if milestone.key?(:Email)
      m = Milestone.create(
        json_data: json_data,
        deadline: milestone[:Deadline],
        system_type: nil,
        user_generated: true,
        milestone_type: milestone[:Type],
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(m)

      facilitators.each do |user_email|

        facilitator = AssignedFacilitator.new(course_project_id: project.id);

        if Staff.exists?(email: user_email)
            facilitator.staff_id = Staff.where(email: user_email).first.id
        elsif Student.exists?(email: user_email)
            facilitator.student_id = Student.where(email: user_email).first.id
        end

        facilitator.save!
        DatabaseHelper.print_validation_errors(facilitator)
      end



    end

    module_students = CourseModule.find(project.course_module_id).students
    team_size = project.team_size.to_i
    current_group = nil
    team_count = 0

    # Run sorting algorithm for student groups
    students_grouped = []

    if project.team_allocation == "random_team_allocation"
        students_grouped = DatabaseHelper.random_group_allocation(team_size, module_students)
    end

    students_grouped.each do |student_subarray|
        current_group = Group.new
        team_count += 1
        current_group.name = "Team " + team_count.to_s
        current_group.course_project_id = project.id
        student_subarray.each do |student|
            current_group.students << student
        end
        current_group.save!
        DatabaseHelper.print_validation_errors(current_group)
    end
  end

  def provision_module_class(module_code, name, lead, class_list=nil)
    student_csv =
      if class_list == nil
        StudentDataHelper.generate_dummy_data_csv_string(
          module_code
        )
      else
        class_list
      end

    # begin
      new_module = CourseModule.find_or_create_by ({
        code: module_code,
        name: name,
        staff: lead
      })
    # rescue ActiveRecord::RecordNotUnique
      # puts "#{WARNING} Module #{module_code} already exists"
    # else
      DatabaseHelper.print_validation_errors(new_module)

      errors = Student.bootstrap_class_list(student_csv)
      if errors.length > 0
        puts "#{WARNING} #{errors.length} students had validation errors, their entries were not committed. Displaying first error:"
        DatabaseHelper.print_validation_errors(errors[0])
      end
    # ensure
      return student_csv
    # end
  end

  def change_class_module(class_csv, module_code)
    csv = CSV.parse(class_csv, headers: true)
    csv.each do |row|
      row[StudentDataHelper::MODULE_CODE_CSV_COLUMN] = module_code
    end
    StudentDataHelper.convert_csv_to_text(csv)
  end

  def create_staff(email)
    x = Staff.find_or_create_by(email: email)
    DatabaseHelper.print_validation_errors(x)
    x
  end

  def get_student_by_module(module_code)
    # puts CourseModule.find_by(code: module_code).students[0]
    CourseModule.find_by(code: module_code).students.all
  end

  def get_student_first_name(student)
    # WARNING, LDAP IS INCREDIBLY SLOW TO QUERY
    un, lookup = ldap_lookup student
    if lookup.all_results.length == 0
      return un
    end
    return lookup.lookup[:givenName][0]
  end

  def get_student_last_name(student)
    # WARNING, LDAP IS INCREDIBLY SLOW TO QUERY
    un, lookup = ldap_lookup student
    if lookup.all_results.length == 0
      return un
    end
    return lookup.lookup[:sn][0]
  end

  ##
  # Takes a list of students, splits them into the given group size randomly
  # and returns the 2-D array of groups.
  def random_group_allocation(team_size, student_list)

    #Randomise students
    shuffled_students = student_list.shuffle
    num_teams = (student_list.size / team_size).floor

    #Create correct size groups
    teams = []
    num_teams.times do
      team = []
      team_size.times do
        team << shuffled_students.pop
      end
      teams << team
    end

    #Allocate remaining students (if any) to random groups
    i = 0
    while shuffled_students.any?
      teams[i] << shuffled_students.pop
      i += 1
    end

    return teams.shuffle

  end

  ##
  # Takes a list of students, splits them into the given group size according to:
  # - Gender
  # - Domicile
  # and returns the 2-D array of groups.
  def random_with_heuristics_allocation(team_size, student_list)
    return random_group_allocation(team_size, student_list) if team_size <= 3

    #Randomise students
    shuffled_students = student_list.shuffle
    num_teams = (student_list.size / team_size).floor

    teams = []
    num_teams.times do
      team = []
      while team.size < team_size

        if team.size.even?
          #Add a random student
          team << shuffled_students.pop
          next
        end

        previous_student = team.last
        titles = TITLES.find { |specific_titles| specific_titles.include?(previous_student.title) }

        #Add a full title and domicile match if found
        full_matches = shuffled_students.select { |student| titles.include?(student.title) && student.fee_status == previous_student.fee_status }
        unless full_matches.empty?
          team << full_matches.first
          shuffled_students.delete(full_matches.first)
          next
        end

        #Add a half title and domicile match if found
        half_matches = shuffled_students.select { |student| titles.include?(student.title) || student.fee_status == previous_student.fee_status }
        unless half_matches.empty?
          team << half_matches.first
          shuffled_students.delete(half_matches.first)
          next
        end

        #Add another random student
        team << shuffled_students.pop
      end
      teams << team
    end

    #Allocate remaining students (if any) to random groups
    i = 0
    while shuffled_students.any?
      teams[i] << shuffled_students.pop
      i += 1
    end

    return teams.shuffle

  end

  ##
  # Takes a list of students, splits them into the given group size according to:
  # - Preferred Teammates
  # - Avoided Teammates
  # - Gender
  # - Domicile
  # and returns the 2-D array of groups.
  def preference_form_group_allocation(team_size, student_list, pref_form_milestone)

  end

  def assign_projects_to_individuals(course_project)
    subproject_popularity = {}

    course_project.groups.each do |g|
      response = g.students.first.milestone_responses.find_by(milestone: course_project.project_preference_deadline)
      subproject =
        if response
          response.json_data["1"]
        else
          # assign least popular subproject
          subproject_popularity.sort_by { |key, value| value }.first[0]
        end

      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1

      g.subproject = Subproject.find(subproject)
    end
  end
  def assign_projects_to_groups(course_project)
    subproject_popularity = {}

    MilestoneResponse.where(milestone: course_project.project_preference_deadline).each do |r|
      group = r.student.groups.find_by(course_project: course_project)
      subproject = r.json_data["1"]

      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1
      g.subproject = Subproject.find(subproject)
    end

    # groups that didnt respond
    course_project.groups.where(subproject: nil).each do |g|
      subproject = subproject_popularity.sort_by { |key, value| value }.first[0]
      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1
      g.subproject = Subproject.find(subproject)
    end
  end

  private

  def ldap_lookup(student)
    # WARNING, LDAP IS INCREDIBLY SLOW TO QUERY
    un =
      if student.kind_of?(String)
        student
      elsif student.kind_of?(Student)
        student.username
      end
    return un, SheffieldLdapLookup::LdapFinder.new(un)
  end

end