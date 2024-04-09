# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'student_data_helper'
require 'database_helper'
require 'csv'

x = Student.find_or_create_by({
  username: "aca21sgt",
  preferred_name: "Sam",
  forename: "Sam",
  title: "Mx",
  ucard_number: "777777777",
  email: "sgttaseff1@sheffield.ac.uk",
  fee_status: :home
})
puts DatabaseHelper.print_validation_errors(x)
puts DatabaseHelper.print_validation_errors(Staff.find_or_create_by({ email: "sgttaseff1@sheffield.ac.uk" }))

Student.find_or_create_by({
  username: "aca21jlh",
  preferred_name: "Josh",
  forename: "Joshua",
  surname: "Henson",
  title: "Mr",
  ucard_number: "123456789",
  email: "jhenson2@sheffield.ac.uk",
  fee_status: :home
})

Staff.find_or_create_by({
  email: "jhenson2@sheffield.ac.uk"
})

Student.find_or_create_by({
  username: "ack21jb",
  preferred_name: "Jakub",
  forename: "Jakub",
  title: "Mr",
  ucard_number: "001793100",
  email: "jbala1@sheffield.ac.uk",
  fee_status: :home
})

Student.find_or_create_by({
  username: "acc22aw",
  preferred_name: "Adam",
  forename: "Adam",
  title: "Mr",
  ucard_number: "001787692",
  email: "awillis4@sheffield.ac.uk",
  fee_status: :home
})

DatabaseHelper.provision_module_class(
  "COM2009",
  "Robotics",
  Staff.find_by(email: "jhenson2@sheffield.ac.uk")
)

students_COM3420 = DatabaseHelper.provision_module_class(
  "COM3420",
  "Software Hut",
  DatabaseHelper.create_staff("emma_norling@sheffield.ac.uk")
)

puts ""

# take the entire COM3420 class and enroll them in another module
DatabaseHelper.provision_module_class(
  "COM2004",
  "Introduction to Software Engineering",
  DatabaseHelper.create_staff("mike.stannet@sheffield.ac.uk"),
  DatabaseHelper.change_class_module(students_COM3420, "COM2004")
)

puts ""

DatabaseHelper.print_validation_errors(CourseProject.find_or_create_by({
  course_module: CourseModule.find_by(code: "COM2009"),
  # dont specify it to leave it as the default {}
  # markscheme_json: {test: "test"}.to_json,
  name: "TurtleBot Project",
  project_allocation: :individual_preference_project_allocation,
  # dont specify it to leave it as the default {}
  # project_choices_json: {test: "test"}.to_json,
  team_allocation: :random,
  team_size: 8
}))