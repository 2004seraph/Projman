class CreateMilestoneResponse < ActiveRecord::Migration[7.0]
  def change
    create_table :milestone_responses do |t|
      t.references :milestone, null: false, foreign_key: { to_table: :milestones }

      t.references :students, null: true
      t.references :staff, null: true

      t.json :json_data, null: false, default: "{}"

      t.timestamps
    end
  end
end
