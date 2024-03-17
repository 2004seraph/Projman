class CreateMilestone < ActiveRecord::Migration[7.0]
  def change
    create_enum :milestone_type, %w[individual staff group live final]

    create_table :milestones do |t|
      t.references :project, null: false, foreign_key: { to_table: :projects }

      t.column :type, :milestone_type, null: false
      t.date :deadline, null: false

      t.json :json_data

      t.timestamps
    end
  end
end
