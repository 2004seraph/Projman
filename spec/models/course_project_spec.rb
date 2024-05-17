# == Schema Information
#
# Table name: course_projects
#
#  id                        :bigint           not null, primary key
#  avoided_teammates         :integer          default(0)
#  markscheme_json           :json
#  name                      :string           default("Unnamed Project"), not null
#  preferred_teammates       :integer          default(0)
#  status                    :enum             default("draft"), not null
#  team_allocation           :enum
#  team_size                 :integer          not null
#  teams_from_project_choice :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  course_module_id          :bigint           not null
#
# Indexes
#
#  index_course_projects_on_course_module_id  (course_module_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_module_id => course_modules.id)
#
require "rails_helper"

RSpec.describe CourseProject, type: :model do
  let!(:course_students) {
    DatabaseHelper.provision_module_class(
      "COM2009",
      "Robotics",
      Staff.find_or_create_by(email: "jhenson2@sheffield.ac.uk")
    )
  }
  let!(:project_gec_style) {
    DatabaseHelper.create_gec_style_project ({
      name:                  "GEC test",
      status:                "preparation",
      module_code:           "COM2009",
      project_deadline:      DateTime.now + 4.minute,
      project_pref_deadline: DateTime.now - 100.minute,
      facilitators: []
    })
  }

  context "lifecycles for GEC-style projects" do
    it "assigns teams when the project preference deadline has passed" do
      expect(project_gec_style.groups.count).to eq 0

      # m = project_gec_style.project_preference_deadline
      # m.deadline = DateTime.now - 100.minutes
      # m.save!
      # m.reload
      # project_gec_style.reload
      # puts DateTime.now
      # puts CourseProject.all.count
      # puts project_gec_style.project_preference_deadline.deadline

      CourseProject.lifecycle_job
      expect(project_gec_style.groups.count).to be > 0
    end
    it "assigns teams when the project preference deadline has passed" do
      expect(project_gec_style.groups.count).to eq 0
      CourseProject.lifecycle_job
      expect(project_gec_style.groups.count).to be > 0
    end
  end
end
