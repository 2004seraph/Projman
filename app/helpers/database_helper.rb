# frozen_string_literal: true

module DatabaseHelper
  PREFIX = '[Database]'
  NOTICE = "#{PREFIX} Notice:".freeze
  WARNING = "#{PREFIX} Warning:".freeze
  ERROR = "#{PREFIX} Error:".freeze

  TITLES = [['Mr'], %w[Miss Ms Mrs], %w[Mx Dr Prof]].freeze

  extend self

  def print_validation_errors(model_instance)
    if !model_instance.valid?
      Rails.logger.debug "#{ERROR} #{model_instance.class.name} instance is invalid:"
      Rails.logger.debug model_instance.errors.full_messages
    else
      Rails.logger.debug "#{NOTICE} #{model_instance.class.name} instance is valid"
    end
  end

  # DATA SEEDING

  def create_course_project(options = {})
    settings = {
      module_code: 'COM3420',
      name: 'Test Project',
      status: 'draft',
      project_choices: ['Choice 1', 'Choice 2'],
      team_size: 4,
      preferred_teammates: 1,
      avoided_teammates: 2,
      team_allocation_mode: 'random_team_allocation',
      project_allocation_mode: 'team_preference_project_allocation',

      project_deadline: DateTime.now + 1.minute,
      project_pref_deadline: DateTime.now + 1.minute,
      team_pref_deadline: DateTime.now + 1.minute,

      milestones: [
        {
          "Name": 'Milestone 1',
          "Deadline": DateTime.now + 1.minute,
          "Email": { "Content": 'This is an email', "Advance": 0 },
          "Comment": 'This is a comment',
          "Type": 'team'
        }
      ],

      facilitators: ['jbala1@sheffield.ac.uk', 'sgttaseff1@sheffield.ac.uk']
    }.merge(options)

    project = CourseProject.find_or_create_by(
      course_module: CourseModule.find_by(code: settings[:module_code]),
      name: settings[:name],
      project_allocation: settings[:project_allocation_mode],
      team_size: settings[:team_size],
      team_allocation: settings[:team_allocation_mode],
      preferred_teammates: settings[:preferred_teammates],
      avoided_teammates: settings[:avoided_teammates],
      status: settings[:status]
    )
    DatabaseHelper.print_validation_errors(project)

    settings[:project_choices].each do |choice|
      subproject = Subproject.create(
        name: choice,
        json_data: '{}',
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(subproject)
    end

    project_deadline_json_data = {
      'Name' => 'Project Deadline',
      'isDeadline' => true,
      'Comment' => '',
      'Email' => { "Content": 'Project Deadline upcoming!', "Advance": 0 }
    }
    project_deadline_milestone = Milestone.create(
      json_data: project_deadline_json_data,
      deadline: settings[:project_deadline],
      system_type: 'project_deadline',
      user_generated: true,
      milestone_type: 'team',
      course_project_id: project.id
    )
    DatabaseHelper.print_validation_errors(project_deadline_milestone)

    if project.project_allocation
      proj_pref_json_data = {
        'Name' => 'Project Preference Deadline',
        'isDeadline' => true,
        'Comment' => '',
        'Email' => { "Content": 'Project preference upcoming!', "Advance": 0 }
      }
      proj_pref_milestone = Milestone.create(
        json_data: proj_pref_json_data,
        deadline: settings[:project_pref_deadline],
        system_type: 'project_preference_deadline',
        user_generated: true,
        milestone_type: 'student',
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(proj_pref_milestone)
    end

    if project.team_allocation != 'random_team_allocation'
      team_pref_json_data = {
        'Name' => 'Teammate Preference Deadline',
        'isDeadline' => true,
        'Comment' => '',
        'Email' => { "Content": 'Teammate preference upcoming!', "Advance": 0 }
      }
      team_pref_milestone = Milestone.create(
        json_data: team_pref_json_data,
        deadline: DateTime.now + 1.minute,
        system_type: 'teammate_preference_deadline',
        user_generated: true,
        milestone_type: 'student',
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(team_pref_milestone)
    end

    settings[:milestones].each do |milestone|
      json_data = {
        'Name' => milestone[:Name],
        'isDeadline' => false,
        'Comment' => milestone[:Comment]
      }
      json_data['Email'] = milestone[:Email] if milestone.key?(:Email)

      m = Milestone.create(
        json_data:,
        deadline: milestone[:Deadline],
        system_type: nil,
        user_generated: true,
        milestone_type: milestone[:Type],
        course_project_id: project.id
      )
      DatabaseHelper.print_validation_errors(m)
    end

    settings[:facilitators].each do |user_email|
      facilitator = AssignedFacilitator.new(course_project_id: project.id)

      if Staff.exists?(email: user_email)
        facilitator.staff_id = Staff.where(email: user_email).first.id
      elsif Student.exists?(email: user_email)
        facilitator.student_id = Student.where(email: user_email).first.id
      end

      facilitator.save!
      DatabaseHelper.print_validation_errors(facilitator)
    end

    module_students = CourseModule.find(project.course_module_id).students
    team_size = project.team_size.to_i
    current_group = nil
    team_count = 0

    # Run sorting algorithm for student groups
    students_grouped = []

    if project.team_allocation == 'random_team_allocation'
      students_grouped = DatabaseHelper.random_group_allocation(team_size, module_students)
    end

    students_grouped.each do |student_subarray|
      current_group = Group.new
      team_count += 1
      current_group.name = "Team #{team_count}"
      current_group.course_project_id = project.id
      student_subarray.each do |student|
        current_group.students << student
      end
      current_group.save!
      DatabaseHelper.print_validation_errors(current_group)
    end
  end

  def provision_module_class(module_code, name, lead, class_list = nil)
    student_csv =
      if class_list.nil?
        StudentDataHelper.generate_dummy_data_csv_string(
          module_code
        )
      else
        class_list
      end

    # begin
    new_module = CourseModule.find_or_create_by({
                                                  code: module_code,
                                                  name:,
                                                  staff: lead
                                                })
    # rescue ActiveRecord::RecordNotUnique
    # puts "#{WARNING} Module #{module_code} already exists"
    # else
    DatabaseHelper.print_validation_errors(new_module)

    errors = Student.bootstrap_class_list(student_csv)
    if errors.length.positive?
      Rails.logger.debug "#{WARNING} #{errors.length} students had validation errors, their entries were not committed. Displaying first error:"
      DatabaseHelper.print_validation_errors(errors[0])
    end
    # ensure
    student_csv
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
    x = Staff.find_or_create_by(email:)
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
    return un if lookup.all_results.empty?

    lookup.lookup[:givenName][0]
  end

  def get_student_last_name(student)
    # WARNING, LDAP IS INCREDIBLY SLOW TO QUERY
    un, lookup = ldap_lookup student
    return un if lookup.all_results.empty?

    lookup.lookup[:sn][0]
  end

  ##
  # Takes a list of students, splits them into the given group size randomly
  # and returns the 2-D array of groups.
  def random_group_allocation(team_size, student_list)
    # Randomise students
    shuffled_students = student_list.shuffle
    num_teams = (student_list.size / team_size).floor

    # Create correct size groups
    teams = []
    num_teams.times do
      team = []
      team_size.times do
        team << shuffled_students.pop
      end
      teams << team
    end

    # Allocate remaining students (if any) to random groups
    i = 0
    while shuffled_students.any?
      teams[i] << shuffled_students.pop
      i += 1
    end

    teams.shuffle
  end

  ##
  # Takes a list of students, splits them into the given group size according to:
  # - Gender
  # - Domicile
  # and returns the 2-D array of groups.
  def random_with_heuristics_allocation(team_size, student_list)
    return random_group_allocation(team_size, student_list) if team_size <= 3

    # Randomise students
    shuffled_students = student_list.shuffle
    num_teams = (student_list.size / team_size).floor

    teams = []
    num_teams.times do
      team = []
      while team.size < team_size

        if team.size.even?
          # Add a random student
          team << shuffled_students.pop
          next
        end

        previous_student = team.last
        titles = TITLES.find { |specific_titles| specific_titles.include?(previous_student.title) }

        # Add a full title and domicile match if found
        full_matches = shuffled_students.select do |student|
          titles.include?(student.title) && student.fee_status == previous_student.fee_status
        end
        unless full_matches.empty?
          team << full_matches.first
          shuffled_students.delete(full_matches.first)
          next
        end

        # Add a half title and domicile match if found
        half_matches = shuffled_students.select do |student|
          titles.include?(student.title) || student.fee_status == previous_student.fee_status
        end
        unless half_matches.empty?
          team << half_matches.first
          shuffled_students.delete(half_matches.first)
          next
        end

        # Add another random student
        team << shuffled_students.pop
      end
      teams << team
    end

    # Allocate remaining students (if any) to random groups
    i = 0
    while shuffled_students.any?
      teams[i] << shuffled_students.pop
      i += 1
    end

    teams.shuffle
  end

  ##
  # Takes a list of students, splits them into the given group size according to:
  # - Preferred Teammates
  # - Avoided Teammates
  # - Gender
  # - Domicile
  # and returns the 2-D array of groups.
  def preference_form_group_allocation(team_size, student_list, pref_form_milestone)
    shuffled_students = student_list.shuffle
    num_teams = (student_list.size / team_size).floor
    teams = []

    # Parse data from preference form responses
    preferences = {}
    avoided = {}
    pref_form_milestone.milestone_responses.each do |response|
      preferences[response.student_id] = response.json_data['preferred']
      avoided[response.student_id] = response.json_data['avoided']
    end

    # Get preferred teammate pairs
    preferred_pairs = []
    preferences.each do |key, value|
      value.each do |preferred_id|
        next if preferences[preferred_id].nil?

        if preferences[preferred_id].include?(key)
          preferred_pairs << [key, preferred_id]
          preferences[preferred_id].delete(key)
        end
      end
    end

    # Concatenate any shared preference pairs
    preferred_pairs.each_with_index do |pair, index|
      preferred_pairs.each_with_index do |other_pair, other_index|
        next if index == other_index

        if (pair & other_pair).any?
          preferred_pairs[index] = (pair + other_pair).uniq
          preferred_pairs[other_index] = []
        end
      end
    end
    preferred_pairs.reject!(&:empty?)

    # Change IDs to Student models
    student_map = {}
    shuffled_students.each { |student| student_map[student.id] = student }
    preferred_pairs.each do |pair|
      pair.map! { |student_id| student_map[student_id] }
      pair.each do |student|
        shuffled_students.delete(student)
      end
    end

    # Initialize and add the preferred teammates to teams
    num_teams.times do |i|
      teams[i] = []
    end

    i = 0
    while preferred_pairs.any?
      i = 0 if i == num_teams
      if avoidance_check(teams[i], preferred_pairs.first, avoided) && teams[i].size < team_size
        teams[i] += preferred_pairs.shift
      end
      i += 1
    end

    # Fill in teams with students chosen via heuristics
    num_teams.times do |i|
      team = teams[i]
      while team.size < team_size

        if team.size.even?
          # Add a random student
          team << shuffled_students.pop
          next
        end

        previous_student = team.last
        titles = TITLES.find { |specific_titles| specific_titles.include?(previous_student.title) }

        # Add a full title and domicile match if found
        full_matches = shuffled_students.select do |student|
          titles.include?(student.title) && student.fee_status == previous_student.fee_status
        end
        unless full_matches.empty?
          team << full_matches.first
          shuffled_students.delete(full_matches.first)
          next
        end

        # Add a half title and domicile match if found
        half_matches = shuffled_students.select do |student|
          titles.include?(student.title) || student.fee_status == previous_student.fee_status
        end
        unless half_matches.empty?
          team << half_matches.first
          shuffled_students.delete(half_matches.first)
          next
        end

        # Add another random student
        team << shuffled_students.pop

      end
    end

    # Allocate remaining students (if any) to random groups
    i = 0
    while shuffled_students.any?
      i = 0 if i == num_teams

      teams[i] << shuffled_students.pop
      i += 1
    end

    teams.shuffle
  end

  def assign_projects_to_individuals(course_project)
    subproject_popularity = {}

    course_project.groups.each do |g|
      response = g.students.first.milestone_responses.find_by(milestone: course_project.project_preference_deadline)
      subproject =
        if response
          response.json_data['1']
        else
          # assign least popular subproject
          (subproject_popularity.min_by { |_key, value| value } || [course_project.subprojects.first.id])[0]
        end

      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1

      g.subproject = Subproject.find(subproject)
      g.save
    end
  end

  def assign_projects_to_groups(course_project)
    subproject_popularity = {}

    MilestoneResponse.where(milestone: course_project.project_preference_deadline).find_each do |r|
      r.student.groups.find_by(course_project:)
      subproject = r.json_data['1']

      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1
      g.subproject = Subproject.find(subproject)
      g.save
    end

    # groups that didnt respond
    course_project.groups.where(subproject: nil).find_each do |g|
      subproject = (subproject_popularity.min_by do |_key, value|
                      value
                    end || [course_project.subprojects.first.id])[0]
      subproject_popularity[subproject] = (subproject_popularity[subproject] || 0) + 1
      g.subproject = Subproject.find(subproject)
      g.save
    end
  end

  private

  # Helper method that checks for avoidance preference responses in planned team additions
  def avoidance_check(team, student_array, avoidance_hash)
    return true if team.empty? || student_array.empty?

    team.each do |team_member|
      student_array.each do |prospect|
        return false if !avoidance_hash[team_member.id].nil? && avoidance_hash[team_member.id].include?(prospect.id)
        return false if !avoidance_hash[prospect.id].nil? && avoidance_hash[prospect.id].include?(team_member.id)
      end
    end
    true
  end

  def ldap_lookup(student)
    # WARNING, LDAP IS INCREDIBLY SLOW TO QUERY
    un =
      if student.is_a?(String)
        student
      elsif student.is_a?(Student)
        student.username
      end
    [un, SheffieldLdapLookup::LdapFinder.new(un)]
  end
end
