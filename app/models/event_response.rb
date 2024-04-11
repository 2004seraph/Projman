# == Schema Information
#
# Table name: event_responses
#
#  id         :bigint           not null, primary key
#  json_data  :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
# Indexes
#
#  index_event_responses_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
class EventResponse < ApplicationRecord
  belongs_to :event
  has_one :group, through: :event
end
