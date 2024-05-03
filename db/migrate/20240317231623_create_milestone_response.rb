# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateMilestoneResponse < ActiveRecord::Migration[7.0]
  def change
    create_table :milestone_responses do |t|
      t.references :milestone, null: false, foreign_key: { to_table: :milestones }

      t.references :student, null: true
      t.references :staff, null: true

      t.json :json_data, null: false, default: '{}'

      t.timestamps
    end
  end
end
