# frozen_string_literal: true

# == Schema Information
#
# Table name: course_projects
#
#  id                  :bigint           not null, primary key
#  avoided_teammates   :integer          default(0)
#  markscheme_json     :json
#  name                :string           default("Unnamed Project"), not null
#  preferred_teammates :integer          default(0)
#  project_allocation  :enum             not null
#  status              :enum             default("draft"), not null
#  team_allocation     :enum
#  team_size           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  course_module_id    :bigint           not null
#
# Indexes
#
#  index_course_projects_on_course_module_id  (course_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_module_id => course_modules.id)
#
