class CreateCourseModule < ActiveRecord::Migration[7.0]
  def change
    create_table :course_modules do |t|
      t.string :name, null: false, limit: 32

      t.timestamps
    end
  end
end
