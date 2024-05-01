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

  attr_accessor :student
  attr_accessor :staff

  def is_student?
    account_type.include?("student")
  end

  def is_staff?
    # if the staff field is populated, manually override
    if staff == nil
      account_type.include?("staff")
    else
      true
    end
  end

  def is_facilitator?
    is_fac = false
    if is_student?
      is_fac |= AssignedFacilitator.exists?(student: student)
    end
    if is_staff?
      is_fac |= AssignedFacilitator.exists?(staff: staff)
    end
    is_fac
  end

  def issue_notification?
    if self.is_staff?
      issues = self.staff.issues
    else
      issues = self.student.events.where(event_type: :issue)
    end
      
    issues.any? { |issue| issue.notification?(self) }
  end
end