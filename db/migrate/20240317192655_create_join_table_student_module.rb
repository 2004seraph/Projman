class CreateJoinTableStudentModule < ActiveRecord::Migration[7.0]
  def change
    create_table :course_modules_students, id: false do |t|
      t.references :student, null: false, foreign_key: true
      t.references :course_module, null: false, foreign_key: true

      t.index [:student_id, :course_module_id], unique: true, name: "modules_students_index"
    end
  end
end
