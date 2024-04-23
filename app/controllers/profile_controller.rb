class ProfileController < ApplicationController
    authorize_resource class: false

    def index
    end
end
