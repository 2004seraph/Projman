# == Schema Information
#
# Table name: event_responses
#
#  id         :bigint           not null, primary key
#  json_data  :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#  staff_id   :bigint
#  student_id :bigint
#
# Indexes
#
#  index_event_responses_on_event_id    (event_id)
#  index_event_responses_on_staff_id    (staff_id)
#  index_event_responses_on_student_id  (student_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
class EventResponse < ApplicationRecord
  belongs_to :event
  has_one :group, through: :event

  belongs_to :staff, optional: true
  belongs_to :student, optional: true

  after_create ->(event_response) { event_response.send_issue_response_email if event_response.event.event_type == 'issue' }

  def send_issue_response_email
    puts "test method being hit"
    issue = Event.find(self.event_id)
    group = Group.find(issue.group_id)
    course_project = CourseProject.find(group.course_project_id)
    course_module = CourseModule.find(course_project.course_module_id)

    if self.staff.present?
      module_lead = Staff.find(self.staff_id)
      recipient_email = module_lead.email
    elsif self.student.present?
      student = Student.find(self.student_id)
      recipient_email = student.email
    end

    IssueResponseMailer.notify_issue_response(self, issue, recipient_email, group, course_project, course_module).deliver_later
  end
end
