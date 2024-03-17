class CreateJoinTableStudentGroup < ActiveRecord::Migration[7.0]
  def change
    create_join_table :students, :groups do |t|
      t.index [:student_id, :group_id]
    end

    add_foreign_key :groups_students, :students, column: :student_id, on_delete: :cascade
    add_foreign_key :groups_students, :groups, column: :group_id, on_delete: :cascade
  end
end
