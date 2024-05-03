# frozen_string_literal: true

class CreateSubproject < ActiveRecord::Migration[7.0]
  def change
    create_table :subprojects do |t|
      t.references :course_project, null: false, foreign_key: { to_table: :course_projects }

      t.string :name, null: false, default: 'Unnamed project choice'
      t.json :json_data, null: false, default: '{}'

      t.timestamps
    end
    add_reference :groups, :subproject, foreign_key: { to_table: :subprojects }, null: true
  end
end
