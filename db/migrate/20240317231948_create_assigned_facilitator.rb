# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateAssignedFacilitator < ActiveRecord::Migration[7.0]
  def change
    create_table :assigned_facilitators do |t|
      t.references :student, null: true
      t.references :staff, null: true

      t.references :course_project, null: false, foreign_key: true

      t.index %i[student_id staff_id course_project_id], unique: true, name: "module_assignment"

      t.timestamps
    end

    add_belongs_to :groups, :assigned_facilitator,
                   foreign_key: { to_table: :assigned_facilitators, on_delete: :nullify }
  end
end
