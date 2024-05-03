# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class PageController < ApplicationController
  authorize_resource class: false, except: :profile

  def index; end

  def profile
    authorize! :read, :page
  end
end
