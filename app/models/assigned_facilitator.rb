# == Schema Information
#
# Table name: assigned_facilitators
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  staff_id   :bigint
#  student_id :bigint
#
# Indexes
#
#  index_assigned_facilitators_on_staff_id    (staff_id)
#  index_assigned_facilitators_on_student_id  (student_id)
#
class AssignedFacilitator < ApplicationRecord
  has_many :groups

  belongs_to :staff, optional: true
  belongs_to :student, optional: true
  belongs_to :course_project

end
