# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateGroup < ActiveRecord::Migration[7.0]
  def change
    create_table :groups do |t|
      t.references :course_project, null: false, foreign_key: { to_table: :course_projects }
      t.string :name, default: 'My Group'
      t.json :profile, default: '{}'

      t.timestamps
    end
  end
end
