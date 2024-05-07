# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateStaff < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'citext'

    create_table :staffs do |t|
      t.citext :email, null: false, index: { unique: { case_sensitive: false } } # , name: 'unique_emails'

      t.boolean :admin, null: false, default: false

      t.timestamps
    end
  end
end
