

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

end