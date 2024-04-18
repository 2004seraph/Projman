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
end
