# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  email          :string(254)      not null
#  fee_status     :enum             not null
#  forename       :string(24)       not null
#  middle_names   :string(64)       default("")
#  personal_tutor :string(64)       default("")
#  preferred_name :string(24)       not null
#  surname        :string(24)       default("")
#  title          :string(4)        not null
#  ucard_number   :string(9)        not null
#  username       :string(16)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'rails_helper'

RSpec.describe Student, type: :model do
  context "Should accept" do
    it "with a valid generated class list" do
      new_module = CourseModule.create ({
        code: "COM3420",
        name: "Software Hut",
        lead_email: "emma_norling@sheffield.ac.uk"
      })

      csv_data = FactoryBot.build(:csv_data)
      Student.bootstrap_class_list csv_data
    end
  end
end