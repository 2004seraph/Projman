# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'student_data_helper'
require 'csv'

def provision_module_class(module_code, name, lead, class_data)
  new_module = CourseModule.create ({
    code: module_code,
    name: name,
    staff: lead
  })

  Student.bootstrap_class_list(class_data)
end

def change_class_module(class_csv, module_code)
  csv = CSV.parse(class_csv, headers: true)
  csv.each do |row|
    row[StudentDataHelper::MODULE_CODE_CSV_COLUMN] = module_code
  end
  StudentDataHelper.convert_csv_to_text(csv)
end

def create_staff(email)
  Staff.create(email: email)
end

class_COM3420 = StudentDataHelper.generate_dummy_data_csv_string(
  "COM3420"
)
provision_module_class(
  "COM3420",
  "Software Hut",
  create_staff("emma_norling@sheffield.ac.uk"),
  class_COM3420
)

# take the entire COM3420 class and enroll them in another module
class_COM2004 = change_class_module(class_COM3420, "COM2004")
provision_module_class(
  "COM2004",
  "Introduction to Software Engineering",
  create_staff("mike.stannet@sheffield.ac.uk"),
  class_COM2004
)