# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateProject < ActiveRecord::Migration[7.0]
  def change
    create_enum :project_status,
                %w[
                  draft
                  preparation
                  live
                  completed
                  archived
                ]

    create_enum :project_team_allocation,
                %w[
                  random
                  preference_form_based
                ]

    create_table :course_projects do |t|
      t.references :course_module, null: false, foreign_key: true

      t.string :name, null: false, default: 'Unnamed Project'
      t.column :status, :project_status, null: false, default: 'draft'

      t.integer :team_size, null: false
      t.column :team_allocation, :project_team_allocation, null: true
      t.integer :preferred_teammates, default: 0
      t.integer :avoided_teammates, default: 0

      t.boolean :teams_from_project_choice, null: false, default: false
      # removed in favour of the subprojects relation
      # t.json :project_choices_json, default: "{}"

      t.json :markscheme_json, default: '{}'

      t.timestamps
    end
  end
end
