# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateEvent < ActiveRecord::Migration[7.0]
  def change
    create_enum :group_event_type, %w[generic milestone chat issue]

    create_table :events do |t|
      t.references :group, null: false, foreign_key: { to_table: :groups }

      t.column :event_type, :group_event_type, null: false
      t.boolean :completed, default: false
      t.json :json_data, null: false, default: '{}'

      t.references :student, null: true
      t.references :staff, null: true

      t.timestamps
    end
  end
end
