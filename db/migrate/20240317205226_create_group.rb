class CreateGroup < ActiveRecord::Migration[7.0]
  def change
    create_table :groups do |t|
      t.references :course_project, null: false, foreign_key: { to_table: :course_projects }
      t.string :name, default: "My Group"
      t.json :profile, default: "{}"

      t.timestamps
    end
  end
end
