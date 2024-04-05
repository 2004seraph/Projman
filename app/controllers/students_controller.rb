class StudentsController < ApplicationController
    def index
    end

    # def create(user)
    #     puts(user.username)
    #     @student = Student.new(username: user.username)
    #     @student.get_info_from_ldap
    #     puts(@student.uid)
    #     if @student.save
    #         redirect_to "/", notice: "Student was successfully created.", status: :see_other
    #     else
    #         redirect_to "/", notice: "Student was unsuccessfully created.", status: :see_other
    #     end
    # end

    # def load(username)
    #     student = Student.find_by(username: username)
    #     puts(student.username)

    #     return student
    # end

    # def create_from_user(user)
    #     @student = Student.new(username: user.username)
    #     @student.get_info_from_ldap
    #     if @student.save
    #         redirect_to "/", notice: "Student was successfully created.", status: :see_other
    #     else
    #         redirect_to "/", notice: "Student was unsuccessfully created.", status: :see_other
    #     end
    # end
end
