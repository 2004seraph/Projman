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

  enum :event_type, { generic: 'generic', milestone: 'milestone', chat: 'chat', issue: 'issue' }
end
