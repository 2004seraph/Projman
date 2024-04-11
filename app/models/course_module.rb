# == Schema Information
#
# Table name: course_modules
#
#  id         :bigint           not null, primary key
#  code       :citext           not null
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
<<<<<<< HEAD
  has_and_belongs_to_many :students, foreign_key: "course_module_code", association_foreign_key: "student_id", join_table: "course_modules_students"
  has_many :course_projects, dependent: :destroy
=======
  has_and_belongs_to_many :students
  has_many :projects, dependent: :destroy
>>>>>>> 3747a175941b6e84bb6d41dc5e04d10846804f8a
  belongs_to :staff

  validates :code, presence: true, uniqueness: { case_sensitive: false }
end
