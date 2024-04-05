class CreateAssignedFacilitator < ActiveRecord::Migration[7.0]
  def change
    create_table :assigned_facilitators do |t|
      t.references :student, null: true
      t.references :staff, null: true

      t.references :course_project

      t.index [:student_id, :staff_id, :course_project_id], unique: true, name: "module_assignment"

      t.timestamps
    end

    add_belongs_to :groups, :assigned_facilitator, foreign_key: { to_table: :assigned_facilitators }
  end
end
