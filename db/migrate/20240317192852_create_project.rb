class CreateProject < ActiveRecord::Migration[7.0]
  def change
    create_enum :project_status,
      %w[
        draft
        student_preference
        student_preference_review
        team_preference
        team_preference_review
        live
        completed
        archived
      ]

    create_enum :project_team_allocation,
      %w[
        random
        preference_form_based
      ]

    create_enum :project_choice_allocation,
      %w[
        random
        single_preference_submission
        team_average_preference
      ]

    create_table :course_projects do |t|
      t.references :course_module, null: false, foreign_key: true

      t.string :name, null: false, default: "Unnamed Project"
      t.column :status, :project_status, null: false, default: "draft"

      t.integer :team_size, null: false
      t.column :team_allocation, :project_team_allocation, null: false
      t.integer :preferred_teammates, default: 0
      t.integer :avoided_teammates, default: 0

      t.column :project_allocation, :project_choice_allocation, null: false
      t.json :project_choices_json, default: "{}"

      t.json :markscheme_json, default: "{}"

      t.timestamps
    end
  end
end
