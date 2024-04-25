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
class Event < ApplicationRecord
  belongs_to :group
  has_one :course_project, through: :group
  has_one :course_module, through: :course_project

  has_many :event_responses, dependent: :destroy

  belongs_to :staff, optional: true
  belongs_to :student, optional: true

  after_create :send_issue_created_email, if: :issue?
  after_update :send_status_update_email, if: :completed_changed? && :issue?

  enum :event_type, { generic: 'generic', milestone: 'milestone', chat: 'chat', issue: 'issue' }

  def self.sorted_by_latest_activity(*conditions)
    query = joins("LEFT OUTER JOIN event_responses ON event_responses.event_id = events.id")
            .select("events.*, COALESCE(MAX(event_responses.created_at), events.updated_at) AS latest_activity")
            .group("events.id")
            .order("latest_activity DESC")

    query = query.where(*conditions) if conditions.present?

    query
  end

  private

  def send_issue_created_email
    group = Group.find(self.group_id)
    course_project = CourseProject.find(group.course_project_id)
    course_module = CourseModule.find(course_project.course_module_id)
    module_lead = Staff.find(course_module.staff_id)
    module_lead_email = module_lead.email
    IssueCreatedMailer.notify_issue_created(self, module_lead_email, group, course_project, course_module).deliver_later
  end

  def send_status_update_email
    group = Group.find(self.group_id)
    course_project = CourseProject.find(group.course_project_id)
    course_module = CourseModule.find(course_project.course_module_id)

    if self.completed?
      student = Student.find(self.student.id)
      recipient_email = student.email
      status = "resolved"
    else
      module_lead = Staff.find(course_module.staff_id)
      recipient_email = module_lead.email
      status = "reopened"
    end

    IssueStatusUpdateMailer.notify_status_update(self, recipient_email, group, course_project, course_module, status).deliver_later
  end
end
