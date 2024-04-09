# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  completed  :boolean          default(FALSE)
#  json_data  :json             not null
#  type       :enum             not null
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

  enum :type, { generic: 'generic', milestone: 'milestone', chat: 'chat', issue: 'issue' }
end
