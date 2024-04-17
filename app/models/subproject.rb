# == Schema Information
#
# Table name: subprojects
#
#  id                :bigint           not null, primary key
#  json_data         :json             not null
#  name              :string           default("Unnamed project choice"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  course_project_id :bigint           not null
#
# Indexes
#
#  index_subprojects_on_course_project_id  (course_project_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_project_id => course_projects.id)
#
class Subproject < ApplicationRecord

  belongs_to :course_project
  belongs_to :course_module, through: :course_project

  has_many :groups
end
