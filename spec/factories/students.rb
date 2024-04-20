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
require 'student_data_helper'

FactoryBot.define do
  # Returns a raw CSV string of student dummy data
  factory :csv_data, class: String do
    transient do
      default_module { "COM3420" }
      num_records { 234 }
    end

    initialize_with { StudentDataHelper.generate_dummy_data_csv_string(
      default_module,
      num_records)
    }
  end

  factory :standard_student, class: Student do
    username {"acc22aw"}
    preferred_name {"Adam"}
    forename {"Adam"}
    title {"Mr"}
    ucard_number {"001787692"}
    email {"awillis4@sheffield.ac.uk"}
    fee_status {:home}
  end
end
