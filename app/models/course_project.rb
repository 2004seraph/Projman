# == Schema Information
#
# Table name: course_projects
#
#  id                   :bigint           not null, primary key
#  avoided_teammates    :integer          default(0)
#  course_module_code   :string           not null
#  markscheme_json      :json
#  name                 :string           not null
#  preferred_teammates  :integer          default(0)
#  project_allocation   :enum             not null
#  project_choices_json :json
#  status               :enum             default("draft"), not null
#  team_allocation      :enum             not null
#  team_size            :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (course_module_code => course_modules.code)
#
class CourseProject < ApplicationRecord
  has_many :groups, dependent: :destroy
  has_many :milestones, dependent: :destroy
  belongs_to :course_module

  validates :name, presence: true

  enum :status, {
    draft: 'draft',
    student_preference: 'student_preference',
    student_preference_review: 'student_preference_review',
    team_preference: 'team_preference',
    team_preference_review: 'team_preference_review',
    live: 'live',
    completed: 'completed',
    archived: 'archived'
  }

  enum :team_allocation, {
    random_team_allocation: 'random',
    preference_based_team_allocation: 'preference_based'
  }

  enum :project_allocation, {
    random_project_allocation: 'random',
    individual_preference_project_allocation: 'individual_preference',
    team_preference_project_allocation: 'team_preference'
  }

end
