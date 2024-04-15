class CreateEvent < ActiveRecord::Migration[7.0]
  def change
    create_enum :group_event_type, %w[generic milestone chat issue]

    create_table :events do |t|
      t.references :group, null: false, foreign_key: { to_table: :groups }

      t.column :event_type, :group_event_type, null: false
      t.boolean :completed, default: false
      t.json :json_data, null: false, default: "{}"

      t.timestamps
    end
  end
end
