# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class CreateStudent < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'citext'

    #  Integer enum: home = 0, overseas = 1
    create_enum :student_fee_status, %w[home overseas]

    create_table :students do |t|
      # id primary key column is implicit
      t.string :preferred_name, null: false, limit: 24
      t.string :forename,       null: false, limit: 24
      t.string :middle_names,   default: '', limit: 64
      t.string :surname,        default: '', limit: 24

      t.citext :username,       null: false, index: { unique: { case_sensitive: false } }  # seems to depend on the number of middle names
      t.string :title,          null: false, limit: 4
      t.column :fee_status,     :student_fee_status, null: false
      t.string :ucard_number,   null: false, limit: 9, index: { unique: true }

      t.citext :email,          null: false, index: { unique: { case_sensitive: false } }  # technical limit of email addresses
      t.string :personal_tutor, default: '', limit: 64

      t.timestamps
    end
  end
end
