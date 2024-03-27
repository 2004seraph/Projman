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
#  course_projects_id      :bigint           not null
#
# Indexes
#
#  index_groups_on_assigned_facilitator_id  (assigned_facilitator_id)
#  index_groups_on_course_projects_id       (course_projects_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_facilitator_id => assigned_facilitators.id)
#  fk_rails_...  (course_projects_id => course_projects.id)
#
class Group < ApplicationRecord
  belongs_to :project
  belongs_to :assigned_facilitator
  has_many :events, dependent: :destroy
  has_and_belongs_to_many :students

end
