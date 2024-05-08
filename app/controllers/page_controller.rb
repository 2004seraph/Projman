# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.


class PageController < ApplicationController
  authorize_resource class: false, except: :profile

  def index; end

  def profile
    authorize! :read, :page
  end

  def request_title_change
    admin = Staff.where(admin: true).first

    requested_title = params[:requested_title]

    ProfileMailer.notify_admin_title_change_request(admin.email, current_user, requested_title).deliver_now

    render "page/profile"
  end
end
