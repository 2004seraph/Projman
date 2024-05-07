# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateJoinTableStudentGroup < ActiveRecord::Migration[7.0]
  def change
    create_join_table :students, :groups do |t|
      t.index %i[student_id group_id]
    end

    add_foreign_key :groups_students, :students, column: :student_id, on_delete: :cascade
    add_foreign_key :groups_students, :groups, column: :group_id, on_delete: :cascade
  end
end
