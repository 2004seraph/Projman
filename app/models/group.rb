# frozen_string_literal: true

# == Schema Information
#
# Table name: groups
#
#  id                      :bigint           not null, primary key
#  name                    :string           default("My Group")
#  profile                 :json
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  assigned_facilitator_id :bigint
#  course_project_id       :bigint           not null
#  subproject_id           :bigint
#
# Indexes
#
#  index_groups_on_assigned_facilitator_id  (assigned_facilitator_id)
#  index_groups_on_course_project_id        (course_project_id)
#  index_groups_on_subproject_id            (subproject_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_facilitator_id => assigned_facilitators.id)
#  fk_rails_...  (course_project_id => course_projects.id)
#  fk_rails_...  (subproject_id => subprojects.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class Group < ApplicationRecord
  belongs_to :course_project
  has_one :course_module, through: :course_project

  belongs_to :subproject, optional: true
  belongs_to :assigned_facilitator, optional: true
  validate :facilitator_must_be_enrolled_on_the_same_module

  has_and_belongs_to_many :students, after_add: :students_must_be_enrolled_on_the_same_module
  has_many :events, dependent: :destroy

  def facilitator
    return nil if assigned_facilitator_id.nil?

    f = AssignedFacilitator.find(assigned_facilitator_id)
    if !f.staff_id.nil?
      Staff.find(f.staff_id)
    elsif !f.student_id.nil?
      Student.find(f.student_id)
    end
  end

  private

  def students_must_be_enrolled_on_the_same_module(student)
    error_msg = "Students must be part of the same module as this group's project"
    return if student.course_projects.include? course_project

    errors.add(:students, error_msg)
    # throw(:abort, error_msg)
  end

  def facilitator_must_be_enrolled_on_the_same_module
    error_msg = "The facilitator must be part of the same module as this group's project"
    return unless assigned_facilitator.present? && assigned_facilitator.course_project != course_project

    errors.add(:assigned_facilitator, error_msg)
    # throw(:abort, error_msg)
  end
end
