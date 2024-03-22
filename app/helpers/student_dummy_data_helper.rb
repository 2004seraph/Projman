require 'csv'
require 'faker'

module StudentDummyDataHelper
  extend self

  def generate_dummy_data_csv_string(num_records = 234, class_module_code = "COM3420")
    data = generate_dummy_data(num_records, class_module_code)
    csv_string = CSV.generate(headers: true) do |csv|
      csv << csv_headers
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

  def csv_headers
    # Define CSV headers
    [
      'Surname', 'Forename', 'Middle Names', 'Title', 'Known As', 'Fee Status',
      'Student Username', 'Ucard No', 'Email', 'Reg. Status', 'Programme',
      'Period', 'Module Code', '1st Grade', '2nd Grade', '3rd Grade', '4th Grade',
      'NFC_Flag', 'HEFCE_Flag', 'Live Registration', 'Attending', 'Date of Birth',
      'Personal Tutor', 'Supervisors'
    ]
  end
end