# frozen_string_literal: true

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
require 'rails_helper'

RSpec.describe Student, type: :model do
  context "Should accept" do
    it "with a valid generated class list" do
      new_module = CourseModule.create ({
        code: "COM3420",
        name: "Software Hut",
        staff: Staff.find_by(email: "emma_norling@sheffield.ac.uk")
      })

      csv_data = FactoryBot.build(:csv_data)
      Student.bootstrap_class_list csv_data
    end
  end
end
