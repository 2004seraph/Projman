class CreateMilestone < ActiveRecord::Migration[7.0]
  def change
    create_enum :milestone_type, %w[student staff team]

    create_table :milestones do |t|
      t.references :course_projects, null: false, foreign_key: { to_table: :course_projects }

      t.column :type, :milestone_type, null: false
      t.date :deadline, null: false

      t.json :json_data, null: false, default: "{}"

      t.timestamps
    end
  end
end
