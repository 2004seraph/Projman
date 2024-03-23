class AdminController < ApplicationController
    
    #GET /admin
    def index
        @admin_module = [["COM3420 Software Hut"], ["COM2009 Robotics"]]
    end

    #GET /admin/new
    def new
    end

    #GET /admin/show/{id}
    def show
    end

end