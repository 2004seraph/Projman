# == Schema Information
#
# Table name: milestones
#
#  id                 :bigint           not null, primary key
#  deadline           :date             not null
#  json_data          :json             not null
#  type               :enum             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  course_projects_id :bigint           not null
#
# Indexes
#
#  index_milestones_on_course_projects_id  (course_projects_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_projects_id => course_projects.id)
#
class Milestone < ApplicationRecord
  has_many :milestone_responses, dependent: :destroy
  belongs_to :course_project

  enum :type, {
    student: 'for_each_student',
    staff: 'for_each_staff',
    team: 'for_each_team',
  }
end
