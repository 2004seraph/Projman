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
#  course_project_id       :bigint           not null
#  subproject_id           :bigint
#
# Indexes
#
#  index_groups_on_assigned_facilitator_id  (assigned_facilitator_id)
#  index_groups_on_course_project_id        (course_project_id)
#  index_groups_on_subproject_id            (subproject_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_facilitator_id => assigned_facilitators.id)
#  fk_rails_...  (course_project_id => course_projects.id)
#  fk_rails_...  (subproject_id => subprojects.id)
#
class Group < ApplicationRecord
  belongs_to :course_project
  belongs_to :assigned_facilitator, optional: true
  has_many :events, dependent: :destroy
  has_and_belongs_to_many :students

  belongs_to :subproject, optional: true
end
