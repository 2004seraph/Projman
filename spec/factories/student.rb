require 'student_dummy_data_helper'

FactoryBot.define do
  # Returns a raw CSV string of student dummy data
  factory :csv_data, class: String do
    transient do
      num_records { 234 }
    end

    initialize_with { StudentDummyDataHelper.generate_dummy_data_csv_string(num_records) }
  end
end