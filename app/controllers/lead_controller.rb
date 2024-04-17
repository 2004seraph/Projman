class LeadController < ApplicationController
  authorize_resource :class => false

  def teams
    # authorize! :read, controller_name.to_sym
  end
end
