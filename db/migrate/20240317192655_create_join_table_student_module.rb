class CreateJoinTableStudentModule < ActiveRecord::Migration[7.0]
  def change
    create_table :course_modules_students, id: false do |t|
      t.references :student, null: false, foreign_key: true
      t.string :course_module_code, null: false

      t.index [:student_id, :course_module_code], unique: true, name: "modules_students_index"
      t.foreign_key :course_modules, column: :course_module_code, primary_key: :code
    end
  end
end
