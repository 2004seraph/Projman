# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

class LeadController < ApplicationController
  authorize_resource class: false

  def teams
    # authorize! :read, controller_name.to_sym
  end
end
