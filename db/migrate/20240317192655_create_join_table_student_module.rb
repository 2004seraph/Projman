class CreateJoinTableStudentModule < ActiveRecord::Migration[7.0]
  def change
    #  for some damn reason the created table is called "modules_students", which is the wrong way round from the definition?
    create_join_table :students, :course_modules do |t|
      t.index [:student_id, :course_module_id], name: "modules_students_index"
    end

    # foreign key constraints
    # "on_delete: :cascade" means this if a module or student is deleted, this table will have any referencing record removed.
    add_foreign_key :course_modules_students, :students, column: :student_id, on_delete: :cascade
    add_foreign_key :course_modules_students, :course_modules, column: :course_module_id, on_delete: :cascade
  end
end
