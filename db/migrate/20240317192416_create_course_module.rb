class CreateCourseModule < ActiveRecord::Migration[7.0]
  def change
    create_table :course_modules, id: false, primary_key: :code do |t|
      t.string :code, null: false
      t.string :name, null: false, limit: 32
      t.string :lead_email, null: false

      t.timestamps

      t.index :code, unique: true
    end
  end
end
