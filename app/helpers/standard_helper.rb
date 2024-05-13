# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

module StandardHelper
  module_function

  def str_to_int(string)
    Integer(string || "")
  rescue ArgumentError
    1
  end
end
