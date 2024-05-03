# frozen_string_literal: true

# == Schema Information
#
# Table name: milestone_responses
#
#  id           :bigint           not null, primary key
#  json_data    :json             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  milestone_id :bigint           not null
#  staff_id     :bigint
#  student_id   :bigint
#
# Indexes
#
#  index_milestone_responses_on_milestone_id  (milestone_id)
#  index_milestone_responses_on_staff_id      (staff_id)
#  index_milestone_responses_on_student_id    (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (milestone_id => milestones.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class MilestoneResponse < ApplicationRecord
  belongs_to :milestone
  has_one :course_project, through: :milestone
  has_one :course_module, through: :course_project

  belongs_to :staff, optional: true
  belongs_to :student, optional: true
end
