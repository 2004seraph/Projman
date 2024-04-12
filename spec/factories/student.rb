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