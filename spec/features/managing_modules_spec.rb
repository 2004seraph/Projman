require 'rails_helper'

describe 'Managing modules' do

    specify 'I can add a module' do

        Student.create({
            username: "acc22aw",
            preferred_name: "Adam",
            forename: "Adam",
            title: "Mr",
            ucard_number: "001787692",
            email: "awillis4@sheffield.ac.uk",
            fee_status: :home
        })
        user = User.create({
            email: 'awillis4@sheffield.ac.uk',
            username: 'acc22aw',
            uid: 'acc22aw',
            mail: 'awillis4@sheffield.ac.uk',
            ou: 'COM',
            dn: nil,
            sn: 'Willis',
            givenname: 'Adam',
            account_type: 'student - ug'
        })
        login_as user
        
        visit '/admin'
        click_on 'Create New'

        fill_in 'course_module_code', with: 'COM1002'
        fill_in 'course_module_name', with: 'Introduction'
        fill_in 'new_module_lead_email', with: 'test@email'
        fill_in 'new_module_lead_email_confirmation', with: 'test@email'

        attach_file 'student_csv', "#{Rails.root}/spec/data/COM1002.csv"

        click_on 'Submit'

        expect(page).to have_content 'Module was successfully created.'
        expect(page).to have_content 'COM1002 Introduction'
    end

end