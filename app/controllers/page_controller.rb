class PageController < ApplicationController
  authorize_resource class: false, except: :profile

  def index
  end

  def profile
    authorize! :read, :page
  end
end