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
class User < ApplicationRecord
  include EpiCas::DeviseHelper

  attr_accessor :student, :staff

  def is_student?
    account_type.include?('student')
  end

  def is_staff?
    # if the staff field is populated, manually override
    if staff.nil?
      account_type.include?('staff')
    else
      true
    end
  end

  def is_facilitator?
    is_fac = false
    is_fac |= AssignedFacilitator.exists?(student:) if is_student?
    is_fac |= AssignedFacilitator.exists?(staff:) if is_staff?
    is_fac
  end

  def is_admin?
    is_admin = false
    if self.is_staff?
      is_admin |= Staff.where(id: staff.id, admin: true).exists?

      if is_admin
        return self.staff.admin
      end
    end
  end

  def issue_notification?
    issues = if is_staff?
               staff.issues
             else
               student.events.where(event_type: :issue)
             end

    issues.any? { |issue| issue.notification?(self) }
  end

  def project_notification?
    if is_student?
      projects = student.course_projects

      return projects.any? { |project| project.project_notification?(self, student.groups.find_by(course_project_id: project.id)) }
    else
      projects = staff.course_projects
    end

    false
  end
end
