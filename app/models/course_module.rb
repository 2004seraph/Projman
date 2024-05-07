# frozen_string_literal: true

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

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CourseModule < ApplicationRecord
  has_and_belongs_to_many :students
  has_many :course_projects, dependent: :destroy
  belongs_to :staff

  validates :code, presence: true, uniqueness: { case_sensitive: false }
end
