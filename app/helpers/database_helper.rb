

module DatabaseHelper
  PREFIX = "[Database]"
  NOTICE = "#{PREFIX} Notice:"
  WARNING = "#{PREFIX} Warning:"
  ERROR = "#{PREFIX} Error:"

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

end