# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

# == Schema Information
#
# Table name: students
#
#  id                 :bigint           not null, primary key
#  account_type       :string
#  current_sign_in_at :datetime
#  current_sign_in_ip :string
#  dn                 :string
#  email              :citext           not null
#  fee_status         :enum             not null
#  forename           :string(24)       not null
#  givenname          :string
#  last_sign_in_at    :datetime
#  last_sign_in_ip    :string
#  mail               :string
#  middle_names       :string(64)       default("")
#  ou                 :string
#  personal_tutor     :string(64)       default("")
#  preferred_name     :string(24)       not null
#  sign_in_count      :integer          default(0), not null
#  sn                 :string
#  surname            :string(24)       default("")
#  title              :string(4)        not null
#  ucard_number       :string(9)        not null
#  uid                :string
#  username           :citext           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_students_on_email         (email)
#  index_students_on_ucard_number  (ucard_number) UNIQUE
#  index_students_on_username      (username) UNIQUE
#
require "student_data_helper"

FactoryBot.define do
  # Returns a raw CSV string of student dummy data
  factory :csv_data, class: String do
    transient do
      default_module { "COM3420" }
      num_records { 234 }
    end

    initialize_with do
      StudentDataHelper.generate_dummy_data_csv_string(
        default_module,
        num_records
      )
    end
  end

  # ALL THE FIELDS IN THE transient BLOCK CAN BE OVERRIDDEN WITH FactoryBot.create(:standard_student_user, .. <attribs> ..)
  factory :standard_student_user, class: User do
    transient do
      # shared between user and student
      email { "awillis4@sheffield.ac.uk" }
      username { "acc22aw" }

      # user attribs
      givenname { "Adam" }
      sn { "Willis" }

      # student attribs
      title { "Mr" }
      preferred_name { "Adam" }
      middle_names { "" }

      ucard_number { "001787692" }
      fee_status { :home }
    end

    ou { "COM" }
    dn { nil }
    account_type { "student - ug" }

    after(:build) do |user, evaluator|
      user.email = evaluator.email
      user.mail = evaluator.email

      user.username = evaluator.username
      user.uid = evaluator.username

      # Set the student attribute of the user to the built student object
      user.student = Student.create(
        preferred_name: evaluator.preferred_name,
        forename:       evaluator.givenname,
        middle_names:   evaluator.middle_names,
        surname:        evaluator.sn,
        username:       evaluator.username,
        title:          evaluator.title,
        fee_status:     evaluator.fee_status,
        ucard_number:   evaluator.ucard_number,
        email:          evaluator.email
      )

      user.save
    end
  end

  # The below factory does not create a valid User object that we can use
  # in the login_as function, see above for a valid example

  # factory :standard_student, class: User do
  #   email { 'awillis4@sheffield.ac.uk' }
  #   username { 'acc22aw' }
  #   preferred_name { 'Adam' }
  #   forename { 'Adam' }
  #   title { 'Mr' }
  #   ucard_number { '001787692' }
  #   fee_status { :home }
  # end
end
