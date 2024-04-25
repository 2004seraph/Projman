# == Schema Information
#
# Table name: milestones
#
#  id                :bigint           not null, primary key
#  deadline          :date             not null
#  json_data         :json             not null
#  milestone_type    :enum             not null
#  system_generated  :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_project_id :bigint           not null
#
# Indexes
#
#  index_milestones_on_course_project_id  (course_project_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_project_id => course_projects.id)
#
class Milestone < ApplicationRecord
  has_many :milestone_responses, dependent: :destroy
  belongs_to :course_project

  enum :milestone_type, {
    student: 'for_each_student',
    staff: 'for_each_staff',
    team: 'for_each_team',
  }
end
