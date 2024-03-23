# == Schema Information
#
# Table name: course_modules
#
#  code       :string           not null, primary key
#  lead_email :string           not null
#  name       :string(32)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_course_modules_on_code  (code) UNIQUE
#
class CourseModule < ApplicationRecord
  has_and_belongs_to_many :students, foreign_key: "course_module_code", association_foreign_key: "student_id", join_table: "course_modules_students"
  has_many :projects

  self.primary_key = :code
end
