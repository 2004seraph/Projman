class Project < ApplicationRecord
  has_many :groups, dependent: :destroy
  has_many :milestones, dependent: :destroy
  belongs_to :module

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
    random: 'random',
    preference_based: 'preference_based'
  }

  enum :project_allocation, {
    random: 'random',
    individual_preference: 'individual_preference',
    team_preference: 'team_preference'
  }
end