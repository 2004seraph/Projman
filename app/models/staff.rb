# frozen_string_literal: true

# == Schema Information
#
# Table name: staffs
#
#  id                  :bigint           not null, primary key
#  admin               :boolean          default(FALSE), not null
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :citext           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_staffs_on_email  (email) UNIQUE
#
class Staff < ApplicationRecord
  # Include default devise modules. Others available are:

  devise :trackable
  has_many :assigned_facilitators, dependent: :destroy

  has_many :course_modules
  has_many :course_projects, through: :course_modules
  has_many :groups, through: :course_projects

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def issues
    issues = []

    user_modules = course_modules

    user_projects = []
    user_modules.each do |user_module|
      user_projects += user_module.course_projects
    end

    project_groups = []
    user_projects.each do |user_project|
      project_groups += user_project.groups
    end

    project_groups.each do |project_group|
      issues += Event.where(event_type: :issue, group_id: project_group.id)
    end

    issues
  end
end
