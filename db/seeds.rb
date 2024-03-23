# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'student_data_helper'

def provision_module_class(module_code)
  new_module = CourseModule.create ({
    code: module_code,
    name: "Software Hut",
    lead_email: "emma_norling@sheffield.ac.uk"
  })
  class_data = StudentDataHelper.generate_dummy_data_csv_string(
    module_code
  )
  Student.bootstrap_class_list(class_data)
end

provision_module_class("COM3420")