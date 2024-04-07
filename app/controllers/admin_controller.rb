class AdminController < ApplicationController
    before_action :set_module, only: %i[ show edit update destroy ]
    
    #GET /admin
    def index
        @admin_modules = CourseModule.all
    end

    #GET /admin/new
    def new
        @new_module = CourseModule.new
    end

    #POST /admin
    def create 

        #Checks for unique module code
        unless (CourseModule.where(code: (params[:course_module][:code]).strip).empty?)
            redirect_to new_admin_path, alert: "The Module Code is already in use."
            return
        end

        #Checks for correct e-mail confirmation
        @lead = params[:new_module_lead_email]
        @confirmation = params[:new_module_lead_email_confirmation]
        unless (@lead == @confirmation)
            redirect_to new_admin_path, alert: "Unsuccesful - E-mail addresses did not match."
            return
        end
        @lead = Staff.where(email: @lead).first
        
        #Creates new staff account and links it to the module if no staff found in system
        if @lead.nil?
            @lead = Staff.new(email: @confirmation)
            unless @lead.save 
                redirect_to admin_path, alert: "Unsuccesful - Invalid e-mail address"
            end    
        end

        #Checks that the student_csv is compatible with the created module
        @student_csv = CSV.read(params[:student_csv].tempfile)
        unless (@student_csv[1][12] == params[:course_module][:code])
            redirect_to new_admin_path, alert: "The Student List Module {#{@student_csv[1][12]}} is not compatible with the Module Code {#{params[:course_module][:code]}}"
            return
        end

        #Creates new module
        @new_module = CourseModule.new(code: params[:course_module][:code], name: params[:course_module][:name], staff_id: @lead.id)
        if @new_module.save
            Student.bootstrap_class_list((params[:student_csv]).read)
            redirect_to '/admin', notice: "Module was successfully created."
        else
            redirect_to new_admin_path, alert: "Creation unsuccesful."
        end
    end

    #GET /admin/{id}
    def show
        @students = @current_module.students
        @module_lead = @current_module.staff
    end

    #PATCH/PUT /admin/{id}
    def update

        @new_name = params[:new_module_name]
        @new_lead = params[:new_module_lead_email]
        @confirmation = params[:new_module_lead_email_confirmation]
        @new_student_list = params[:new_module_student_list]

        #Update Module Name modal
        unless @new_name.nil?

            @current_module.update_attribute(:name, @new_name)

            if @current_module.valid?
                redirect_to admin_path, notice: "Module Name updated successfully."
            else
                redirect_to admin_path, alert: "Update unsuccessful - Invalid name."
            end
        end

        #Update Module Lead modal
        unless @new_lead.nil?
            
            #Checks for correct e-mail confirmation
            unless (@new_lead == @confirmation)
                redirect_to admin_path, alert: "Update unsuccesful - E-mail addresses did not match."
                return
            end

            @new_lead = Staff.where(email: @new_lead).first
            
            #Creates new staff account and links it to the module if no staff found in system
            if @new_lead.nil?
                @new_lead = Staff.new(email: @confirmation)

                unless @new_lead.save 
                    redirect_to admin_path, alert: "Update unsuccesful - Invalid e-mail address."
                    return
                end
            end

            @current_module.update_attribute(:staff_id, @new_lead.id)

            if @current_module.valid?
                redirect_to admin_path, notice: "Module Leader updated successfully."
            else
                redirect_to admin_path, alert: "Update unsuccesful - Invalid e-mail."
            end
        end

        #Update Module Student List modal
        unless @new_student_list.nil?

            #Checks that the student_csv is compatible with the current module
            @parsed_csv = CSV.read(@new_student_list)
            unless (@parsed_csv[1][12] == @current_module.code)
                redirect_to admin_path, alert: "The Student List Module {#{@parsed_csv[1][12]}} is not compatible with the Module Code {#{@current_module.code}}"
                return
            end

            #Removes old student list and adds new one
            @current_module.students.clear
            Student.bootstrap_class_list(@new_student_list.read)
            redirect_to admin_path, notice: "Student List updated successfully."
        end

    end

    private

      def set_module
        @current_module = CourseModule.find(params[:id])
      end
  
      def module_params
        params.require(:course_module).permit(:code, :name, :staff_id, :student_csv)
      end
      
end