# == Schema Information
#
# Table name: course_projects
#
#  id                   :bigint           not null, primary key
#  avoided_teammates    :integer          default(0)
#  markscheme_json      :json
#  name                 :string           default("Unnamed Project"), not null
#  preferred_teammates  :integer          default(0)
#  project_allocation   :enum             not null
#  project_choices_json :json
#  status               :enum             default("draft"), not null
#  team_allocation      :enum             not null
#  team_size            :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  course_module_id     :bigint           not null
#
# Indexes
#
#  index_course_projects_on_course_module_id  (course_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_module_id => course_modules.id)
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

  enum :project_allocation, {
    random_project_allocation: 'random',
    single_preference_project_allocation: 'single_preference_submission',
    team_preference_project_allocation: 'team_average_preference'
  }

  enum :team_allocation, {
    random_team_allocation: 'random',
    preference_form_based: 'preference_form_based'
  }

end
