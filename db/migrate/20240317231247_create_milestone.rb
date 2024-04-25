class CreateMilestone < ActiveRecord::Migration[7.0]
  def change
    create_enum :milestone_type, %w[for_each_student for_each_staff for_each_team]

    create_table :milestones do |t|
      t.references :course_project, null: false, foreign_key: { to_table: :course_projects }

      t.column :milestone_type, :milestone_type, null: false
      t.boolean :system_generated, null: false, default: false
      t.date :deadline, null: false

      t.json :json_data, null: false, default: "{}"

      t.timestamps
    end
  end
end
