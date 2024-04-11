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
#
# Indexes
#
#  index_events_on_group_id  (group_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#
class Event < ApplicationRecord
  belongs_to :group

  enum :event_type, { generic: 'generic', milestone: 'milestone', chat: 'chat', issue: 'issue' }
end
