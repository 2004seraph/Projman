# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  completed  :boolean          default(FALSE)
#  event_type :enum             not null
#  json_data  :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint           not null
#  staff_id   :bigint
#  student_id :bigint
#
# Indexes
#
#  index_events_on_group_id    (group_id)
#  index_events_on_staff_id    (staff_id)
#  index_events_on_student_id  (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class Event < ApplicationRecord
  belongs_to :group
  has_one :course_project, through: :group
  has_one :course_module, through: :course_project

  has_many :event_responses, dependent: :destroy

  belongs_to :staff, optional: true
  belongs_to :student, optional: true

  after_create :send_issue_created_email, if: :issue?
  after_update :send_status_update_email, if: :completed_changed? && :issue?

  enum :event_type, { generic: "generic", milestone: "milestone", chat: "chat", issue: "issue" }

  def notification?(user)
    if !completed? &&
       ((user.is_staff? && event_responses.empty?) ||
       (user.is_staff? && event_responses.last.student_id.present? && json_data["reopened_by"] == "") ||
       (user.is_staff? && (json_data["reopened_by"] != "" && json_data["reopened_by"] != user.staff.email)) ||
       (user.is_student? && !event_responses.empty? && event_responses.last.staff_id.present? && json_data["reopened_by"] == "") ||
       (user.is_student? && (json_data["reopened_by"] != "" && json_data["reopened_by"] != user.student.username)))
      # when deployed this to change above elsif to commented line
      # elsif user.is_student? && !issue.event_responses.empty? && issue.event_responses.last.staff_id.present?

      true
    else
      false
    end
  end

  def self.chat_notification?(user, group)
    return if group.nil?

    group_chat_messages = group.events.where(event_type: :chat)

    most_recent_messager = group_chat_messages&.last&.student_id || group_chat_messages&.last&.staff_id

    if !most_recent_messager.nil? && ((user.is_student? && most_recent_messager != user.student.id) || (user.is_staff? && most_recent_messager != user.staff.id))
      true
    else
      false
    end
  end

  def self.sorted_by_latest_activity(*conditions)
    query = joins("LEFT OUTER JOIN event_responses ON event_responses.event_id = events.id")
            .select("events.*, COALESCE(MAX(event_responses.created_at), events.updated_at) AS latest_activity")
            .group("events.id")
            .order("latest_activity DESC")

    query.where(*conditions) if conditions.present?
  end

  private
    def send_issue_created_email
      group = Group.find(group_id)
      course_project = CourseProject.find(group.course_project_id)
      course_module = CourseModule.find(course_project.course_module_id)
      module_lead = Staff.find(course_module.staff_id)
      module_lead_email = module_lead.email
      IssueCreatedMailer.notify_issue_created(self, module_lead_email, group, course_project,
                                              course_module).deliver_later
    end

    def send_status_update_email
      group = Group.find(group_id)
      course_project = CourseProject.find(group.course_project_id)
      course_module = CourseModule.find(course_project.course_module_id)

      if completed?
        student = Student.find(self.student.id)
        recipient_email = student.email
        status = "resolved"
      else
        module_lead = Staff.find(course_module.staff_id)
        recipient_email = module_lead.email
        status = "reopened"
      end

      IssueStatusUpdateMailer.notify_status_update(self, recipient_email, group, course_project, course_module,
                                                   status).deliver_later
    end
end
