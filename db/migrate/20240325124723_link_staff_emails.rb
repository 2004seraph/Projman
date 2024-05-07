# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class LinkStaffEmails < ActiveRecord::Migration[7.0]
  def change
    # add_foreign_key :course_modules, :staffs, column: :lead_email, primary_key: :email
    add_reference :course_modules, :staff, foreign_key: { to_table: :staffs }
  end
end
