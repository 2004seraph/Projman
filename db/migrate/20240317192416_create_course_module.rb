# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateCourseModule < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'citext'

    create_table :course_modules do |t|
      t.citext :code, null: false, index: { unique: { case_sensitive: false } }
      t.string :name, null: false, limit: 64

      t.timestamps
    end
  end
end
