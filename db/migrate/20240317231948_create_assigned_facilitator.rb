class CreateAssignedFacilitator < ActiveRecord::Migration[7.0]
  def change
    create_table :assigned_facilitators do |t|
      t.references :student, null: true
      t.references :staff, null: true

      t.timestamps
    end

    add_belongs_to :groups, :assigned_facilitator, foreign_key: { to_table: :assigned_facilitators }
  end
end
