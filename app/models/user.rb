# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  account_type       :string
#  current_sign_in_at :datetime
#  current_sign_in_ip :string
#  dn                 :string
#  email              :citext           default(""), not null
#  givenname          :string
#  last_sign_in_at    :datetime
#  last_sign_in_ip    :string
#  mail               :string
#  ou                 :string
#  sign_in_count      :integer          default(0), not null
#  sn                 :string
#  uid                :string
#  username           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_users_on_email     (email)
#  index_users_on_username  (username)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

# Represents a temporary user in the system after logging in, before the
# the infomation is used retrieve either staff or student record.

class User < ApplicationRecord
  include EpiCas::DeviseHelper

  attr_accessor :student, :staff

  def is_student?
    is_student = Student.where(email:).exists?
    is_student |= account_type&.include?("student")
    is_student |= !student.nil?
    is_student
  end

  def is_staff?
    # # if the staff field is populated, manually override
    # if staff.nil?
    #   account_type.include?('staff')
    # else
    #   true
    # end

    is_staff = Staff.where(email:).exists?
    is_staff |= account_type&.include?("staff")
    is_staff |= !staff.nil?
    is_staff
  end

  def is_facilitator?
    is_fac = false
    is_fac |= AssignedFacilitator.exists?(student:) if is_student?
    is_fac |= AssignedFacilitator.exists?(staff:) if is_staff?
    is_fac
  end

  def is_admin?
    is_admin = false
    return unless is_staff?

    is_admin |= Staff.where(id: staff.id, admin: true).exists?

    return unless is_admin

    staff.admin
  end

  def issue_notification?
    issues =
      if is_staff?
        staff.issues
      else
        student.events.where(event_type: :issue)
      end

    issues.any? { |issue| issue.notification?(self) }
  end

  def project_notification?
    if is_staff?
      return false
    elsif is_student?
      projects = student.course_projects

      return projects.any? do |project|
        project.project_notification?(self, student.groups.find_by(course_project_id: project.id))
      end
    end

    false
  end
end
