# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateMilestone < ActiveRecord::Migration[7.0]
  def change
    create_enum :milestone_milestone_type, %w[for_each_student for_each_staff for_each_team]
    create_enum :milestone_system_type,
                %w[teammate_preference_deadline project_preference_deadline project_deadline mark_scheme]

    create_table :milestones do |t|
      t.references :course_project, null: false, foreign_key: { to_table: :course_projects }

      t.column    :milestone_type, :milestone_milestone_type, null: false
      t.timestamp :deadline,                                  null: false
      t.json      :json_data,                                 null: false, default: "{}"

      t.boolean   :user_generated,                            null: false, default: false

      t.column    :system_type, :milestone_system_type, null: true
      t.boolean   :executed, null: false, default: false

      t.timestamps
    end
  end
end
