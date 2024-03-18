# == Schema Information
#
# Table name: groups
#
#  id                      :bigint           not null, primary key
#  name                    :string           default("My Group")
#  profile                 :json
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  assigned_facilitator_id :bigint
#  project_id              :bigint           not null
#
# Indexes
#
#  index_groups_on_assigned_facilitator_id  (assigned_facilitator_id)
#  index_groups_on_project_id               (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_facilitator_id => assigned_facilitators.id)
#  fk_rails_...  (project_id => projects.id)
#
class Group < ApplicationRecord
  belongs_to :project
  has_many :students
  has_many :events
  has_and_belongs_to_many :students

end