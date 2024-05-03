# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class AddCasTicketToSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :sessions, :cas_ticket, :string, index: true
  end
end
