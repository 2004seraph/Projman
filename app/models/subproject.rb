# frozen_string_literal: true

# == Schema Information
#
# Table name: subprojects
#
#  id                :bigint           not null, primary key
#  json_data         :json             not null
#  name              :string           default("Unnamed project choice"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_project_id :bigint           not null
#
# Indexes
#
#  index_subprojects_on_course_project_id  (course_project_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_project_id => course_projects.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class Subproject < ApplicationRecord
  belongs_to :course_project
  has_one :course_module, through: :course_project

  has_many :groups, dependent: :nullify
end
