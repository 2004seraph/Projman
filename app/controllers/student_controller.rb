class StudentController < ApplicationController
    # load_and_authorize_resource
    skip_authorization_check
    helper_method :update_selection

    def index
        if session[:current_selection].nil?
            session[:current_selection] = ["current selection"]
        end
    end

    def update_selection
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        puts @text_value
        session[:current_selection] << 'input_text' # Need to get data from text box, and confirm there is a student not in that module.
        puts session[:current_selection]
        # send updated current_selection back to the view.
    end
=begin
    def confirm_selection
        puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    end
=end
    # def remove_students
    # end
end
