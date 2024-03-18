# == Schema Information
#
# Table name: assigned_facilitators
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  student_id :bigint
#
# Indexes
#
#  index_assigned_facilitators_on_student_id  (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (student_id => students.id)
#
class AssignedFacilitator < ApplicationRecord
  belongs_to :group

end
