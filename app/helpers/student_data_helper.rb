require 'csv'
require 'faker'

module StudentDataHelper
  extend self

  # The four members below (two constants and one function) are
  # how you define the schema for the class list CSV file that
  # the app will ingest to add students to modules.

  # Every single CSV header which the database uses MUST be declared here.
  # The rest are here for testing.
  def csv_headers
    # Define CSV headers
    [
      'Surname', 'Forename', 'Middle Names',
      'Title',
      'Known As',
      'Fee Status',
      'Student Username',
      'Ucard No',
      'Email',
      'Reg. Status',
      'Programme',
      'Period',
      'Module Code',
      '1st Grade', '2nd Grade', '3rd Grade', '4th Grade',
      'NFC_Flag', 'HEFCE_Flag', 'Live Registration', 'Attending',
      'Date of Birth',
      'Personal Tutor', 'Supervisors'
    ]
  end

  # the specific CSV field name of the student module enrollment.
  MODULE_CODE_CSV_COLUMN = "Module Code"

  # the parser automatically replaces spaces with _ and converts the
  # string to lowercase, if this does not map to the correct field
  # in the database, you can declare an explicit mapping below.
  EXPLICIT_CSV_TO_FIELD_LINK = {
    "Known As": "preferred_name",
    "Student Username": "username",
    "Ucard No": "ucard_number"
  }

  # if any CSV cells require transforming the data
  # to the correct format for the database
  CSV_VALUE_TRANSLATIONS = {
    fee_status: lambda { |s|
      s.force_encoding('UTF-8').parameterize.to_sym
    },
    username: lambda { |s|
      s.upcase
    }
  }


  def generate_dummy_data_csv_string(class_module_code = "COM3420", num_records = 234)
    data = generate_dummy_data(num_records, class_module_code)
    convert_csv_to_text(data, csv_headers)
  end

  def convert_csv_to_text(data, headers = csv_headers)
    csv_string = CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << row }
    end
    csv_string
  end

  private

  def generate_dummy_data(num_records, class_module_code)
    data = []
    num_records.times do
      surname = Faker::Name.last_name
      forename = Faker::Name.first_name
      middle_names = Array.new(rand(0..2)) { Faker::Name.last_name }.join(' ')
      title = %w[Mr Ms Mrs Mx Miss].sample
      known_as = Faker::Name.first_name
      fee_status = %w[Home Overseas].sample
      student_username = "AC#{[*'A'..'Z'].sample}#{rand(19..22)}#{forename[0]}#{surname[0]}"
      ucard_no = Faker::Number.number(digits: 9)
      email = Faker::Internet.email
      reg_status = 'Fully Registered'
      programme = %w[COMU05 COMU117 COMU39 COMU101 COMU06 COMU43].sample
      period = 'B'
      module_code = class_module_code
      grades = ['-'] * 4
      nfc_flag = '-'
      hefce_flag = 'Yes'
      live_registration = 'Y'
      attending = 'Y'
      dob = Faker::Date.birthday(min_age: 16, max_age: 30)
      personal_tutor = Faker::Name.name
      supervisors = ''

      data << [
        surname, forename, middle_names, title, known_as, fee_status, student_username,
        ucard_no, email, reg_status, programme, period, module_code,
        *grades, nfc_flag, hefce_flag, live_registration, attending, dob,
        personal_tutor, supervisors
      ]
    end
    data
  end
end