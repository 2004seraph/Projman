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

sam = Student.find_or_create_by({
  username: "aca21sgt",
  preferred_name: "Sam",
  forename: "Sam",
  title: "Mx",
  ucard_number: "777777777",
  email: "sgttaseff1@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.print_validation_errors(sam)
sam_staff = Staff.find_or_create_by({ email: "sgttaseff1@sheffield.ac.uk", admin: false })
# DatabaseHelper.print_validation_errors(sam_staff)

josh = Student.find_or_create_by({
  username: "aca21jlh",
  preferred_name: "Josh",
  forename: "Joshua",
  surname: "Henson",
  title: "Mr",
  ucard_number: "123456789",
  email: "jhenson2@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.create_staff("jhenson2@sheffield.ac.uk")

jakub = Student.find_or_create_by({
  username: "ack21jb",
  preferred_name: "Jakub",
  forename: "Jakub",
  title: "Mr",
  ucard_number: "001793100",
  email: "jbala1@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.create_staff("jbala1@sheffield.ac.uk")

adam = Student.find_or_create_by({
  username: "acc22aw",
  preferred_name: "Adam",
  forename: "Adam",
  title: "Mr",
  ucard_number: "001787692",
  email: "awillis4@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.create_staff("awillis4@sheffield.ac.uk")

oliver = Student.find_or_create_by({
  username: "aca22op",
  preferred_name: "Oliver",
  forename: "Oliver",
  surname: "Pickford",
  title: "Mr",
  ucard_number: "001796094",
  email: "opickford1@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.create_staff("opickford1@sheffield.ac.uk")

nahyan = Student.find_or_create_by({
  username: "acb21nk",
  preferred_name: "Nahyan",
  forename: "Nahyan",
  surname: "Khan",
  title: "Mr",
  ucard_number: "001790710",
  email: "nkhan10@sheffield.ac.uk",
  fee_status: :home
})
DatabaseHelper.create_staff("nkhan10@sheffield.ac.uk")

puts ""

robotics_class = DatabaseHelper.provision_module_class(
  "COM2009",
  "Robotics",
  Staff.find_by(email: "jhenson2@sheffield.ac.uk")
)
sam.enroll_module "COM2009"
josh.enroll_module "COM2009"
jakub.enroll_module "COM2009"
adam.enroll_module "COM2009"
oliver.enroll_module "COM2009"
nahyan.enroll_module "COM2009"

students_COM3420 = DatabaseHelper.provision_module_class(
  "COM3420",
  "Software Hut",
  DatabaseHelper.create_staff("sgttaseff1@sheffield.ac.uk"),
  DatabaseHelper.change_class_module(robotics_class, "COM3420")
)
# sam.enroll_module "COM3420"
josh.enroll_module "COM3420"
jakub.enroll_module "COM3420"
adam.enroll_module "COM3420"
oliver.enroll_module "COM3420"
nahyan.enroll_module "COM3420"

DatabaseHelper.provision_module_class(
  "COM9999",
  "Systems and Security",
  DatabaseHelper.create_staff("jbala1@sheffield.ac.uk"),
  DatabaseHelper.change_class_module(robotics_class, "COM9999")
)
sam.enroll_module "COM9999"
josh.enroll_module "COM9999"
jakub.enroll_module "COM9999"
adam.enroll_module "COM9999"
oliver.enroll_module "COM9999"
nahyan.enroll_module "COM9999"


# take the entire COM3420 class and enroll them in another module
DatabaseHelper.provision_module_class(
  "COM2004",
  "Introduction to Software Engineering",
  DatabaseHelper.create_staff("mike.stannet@sheffield.ac.uk"),
  DatabaseHelper.change_class_module(robotics_class, "COM2004")
)
sam.enroll_module "COM2004"
josh.enroll_module "COM2004"
jakub.enroll_module "COM2004"
adam.enroll_module "COM2004"
oliver.enroll_module "COM2004"
nahyan.enroll_module "COM2004"

# Testing module for oliver
DatabaseHelper.provision_module_class(
  "COMOLIVER",
  "Oliver's Project",
  DatabaseHelper.create_staff("opickford1@sheffield.ac.uk"),
  DatabaseHelper.change_class_module(robotics_class, "COMOLIVER")
)
sam.enroll_module "COMOLIVER"
josh.enroll_module "COMOLIVER"
jakub.enroll_module "COMOLIVER"
adam.enroll_module "COMOLIVER"
oliver.enroll_module "COMOLIVER"
nahyan.enroll_module "COMOLIVER"


puts ""

DatabaseHelper.print_validation_errors(CourseProject.find_or_create_by({
  course_module: CourseModule.find_by(code: "COM2009"),
  # dont specify it to leave it as the default {}
  # markscheme_json: {test: "test"}.to_json,
  name: "TurtleBot Project",
  project_allocation: :single_preference_project_allocation,
  # dont specify it to leave it as the default {}
  # project_choices_json: {test: "test"}.to_json,
  team_allocation: :random_team_allocation,
  team_size: 8
}))

DatabaseHelper.print_validation_errors(CourseProject.find_or_create_by({
  course_module: CourseModule.find_by(code: "COM2009"),
  # dont specify it to leave it as the default {}
  # markscheme_json: {test: "test"}.to_json,
  name: "Miro",
  project_allocation: :single_preference_project_allocation,
  # dont specify it to leave it as the default {}
  # project_choices_json: {test: "test"}.to_json,
  team_allocation: :random_team_allocation,
  team_size: 4
}))

DatabaseHelper.print_validation_errors(CourseProject.find_or_create_by({
  course_module: CourseModule.find_by(code: "COM3420"),
  # dont specify it to leave it as the default {}
  # markscheme_json: {test: "test"}.to_json,
  name: "AI Project",
  project_allocation: :single_preference_project_allocation,
  # dont specify it to leave it as the default {}
  # project_choices_json: {test: "test"}.to_json,
  team_allocation: :random_team_allocation,
  team_size: 4
}))

puts ""

DatabaseHelper.print_validation_errors(AssignedFacilitator.find_or_create_by({
  course_project: CourseProject.find_by(name: "AI Project"),
  student: Student.find_by(email: "sgttaseff1@sheffield.ac.uk")
}))

DatabaseHelper.print_validation_errors(AssignedFacilitator.find_or_create_by({
  course_project: CourseProject.find_by(name: "TurtleBot Project"),
  staff: Staff.find_by(email: "jhenson2@sheffield.ac.uk")
}))

DatabaseHelper.print_validation_errors(AssignedFacilitator.find_or_create_by({
  course_project: CourseProject.find_by(name: "AI Project"),
  staff: Staff.find_by(email: "opickford1@sheffield.ac.uk")
}))

DatabaseHelper.print_validation_errors(AssignedFacilitator.find_or_create_by({
  course_project: CourseProject.find_by(name: "TurtleBot Project"),
  staff: Staff.find_by(email: "opickford1@sheffield.ac.uk")
}))

puts ""

DatabaseHelper.print_validation_errors(Group.find_or_create_by({
  name: "Team 28",
  assigned_facilitator:AssignedFacilitator.find_by(staff: Staff.find_by(email: "jhenson2@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "TurtleBot Project")),
  course_project: CourseProject.find_by(name: "TurtleBot Project")
}))

DatabaseHelper.print_validation_errors(Group.find_or_create_by({
  name: "Team 29",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "jhenson2@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "TurtleBot Project")),
  course_project: CourseProject.find_by(name: "TurtleBot Project")
}))

DatabaseHelper.print_validation_errors(Group.find_or_create_by({
  name: "Team 5",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "sgttaseff1@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "AI Project")),
  course_project: CourseProject.find_by(name: "AI Project")
}))

DatabaseHelper.print_validation_errors(Group.find_or_create_by({
  name: "Team 2",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "sgttaseff1@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "Miro")),
  course_project: CourseProject.find_by(name: "Miro")
}))

group = Group.find_or_create_by({
  name: "Team 6",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "sgttaseff1@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "AI Project")),
  course_project: CourseProject.find_by(name: "AI Project")
})
group.students << oliver
group.students << adam
group.students << jakub
group.students << josh

group2 = Group.find_or_create_by({
  name: "Team 1",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "jhenson2@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "TurtleBot Project")),
  course_project: CourseProject.find_by(name: "TurtleBot Project")
})
group2.students << josh
group2.students << sam
group2.students << oliver

group3 = Group.find_or_create_by({
  name: "Team 2",
  assigned_facilitator: AssignedFacilitator.find_by(staff: Staff.find_by(email: "opickford1@sheffield.ac.uk"),
    course_project: CourseProject.find_by(name: "TurtleBot Project")),
  course_project: CourseProject.find_by(name: "TurtleBot Project")
})
group3.students << sam
group3.students << oliver
group3.students << jakub