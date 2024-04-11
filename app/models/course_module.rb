# == Schema Information
#
# Table name: course_modules
#
#  code       :string           not null, primary key
#  name       :string(64)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  staff_id   :bigint
#
# Indexes
#
#  index_course_modules_on_code      (code) UNIQUE
#  index_course_modules_on_staff_id  (staff_id)
#
# Foreign Keys
#
#  fk_rails_...  (staff_id => staffs.id)
#
class CourseModule < ApplicationRecord
  has_and_belongs_to_many :students, foreign_key: "course_module_code", association_foreign_key: "student_id", join_table: "course_modules_students"
  has_many :course_projects, dependent: :destroy
  belongs_to :staff

  self.primary_key = :code
end
