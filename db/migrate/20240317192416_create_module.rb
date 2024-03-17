class CreateModule < ActiveRecord::Migration[7.0]
  def change
    create_table :modules do |t|
      t.string :name, null: false, limit: 32

      t.timestamps
    end
  end
end
