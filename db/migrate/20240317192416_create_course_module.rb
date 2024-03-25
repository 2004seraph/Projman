class CreateCourseModule < ActiveRecord::Migration[7.0]
  def change
    create_table :course_modules, id: false, primary_key: :code do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :name, null: false, limit: 64

      t.timestamps
    end
  end
end
