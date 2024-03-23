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
        preference_based
      ]

    create_enum :project_choice_allocation,
      %w[
        random
        individual_preference
        team_preference
      ]

    create_table :projects do |t|
      t.string :course_module_code, null: false

      t.string :name, null: false
      t.column :status, :project_status, null: false

      t.integer :team_size, null: false
      t.column :team_allocation, :project_team_allocation, null: false
      t.integer :preferred_teammates, default: 0
      t.integer :avoided_teammates, default: 0

      t.column :project_allocation, :project_choice_allocation, null: false
      t.json :project_choices_json, default: "{}"

      t.json :markscheme_json, default: "{}"

      t.timestamps

      t.foreign_key :course_modules, column: :course_module_code, primary_key: :code
    end
  end
end
