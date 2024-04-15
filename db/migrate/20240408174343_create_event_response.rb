class CreateEventResponse < ActiveRecord::Migration[7.0]
  def change
    create_table :event_responses do |t|
      t.references :event, null: false, foreign_key: { to_table: :events }

      # optional 'owner' of the response, for authorization
      t.references :student, null: true

      t.json :json_data, null: false, default: "{}"

      t.timestamps
    end
  end
end
